# MONITORING SERVER

resource "aws_iam_role" "monitoring" {
  name = "${var.project_name}-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-monitoring-role"
  }
}

# Allow monitoring EC2 to use Systems Manager
resource "aws_iam_role_policy_attachment" "monitoring_ssm" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allow Prometheus to discover running EC2 instances
resource "aws_iam_role_policy" "monitoring_ec2_discovery" {
  name = "${var.project_name}-monitoring-ec2-discovery"
  role = aws_iam_role.monitoring.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]

        Resource = "*"
      }
    ]
  })
}

# Attach monitoring IAM role to monitoring EC2
resource "aws_iam_instance_profile" "monitoring" {
  name = "${var.project_name}-monitoring-profile"
  role = aws_iam_role.monitoring.name
}

# Monitoring EC2 instance
resource "aws_instance" "monitoring" {
  ami           = data.aws_ssm_parameter.amazon_linux.value
  instance_type = "t3.small"

  subnet_id = aws_subnet.monitoring_a.id

  vpc_security_group_ids = [
    aws_security_group.monitoring.id
  ]

  iam_instance_profile = aws_iam_instance_profile.monitoring.name

  associate_public_ip_address = false

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash

    # Update Linux and install Docker
    dnf update -y
    dnf install -y docker

    systemctl enable docker
    systemctl start docker

    # Create monitoring configuration folders
    mkdir -p /opt/monitoring/prometheus
    mkdir -p /opt/monitoring/grafana/provisioning/datasources
    mkdir -p /opt/monitoring/blackbox

    # Create Prometheus configuration
    cat > /opt/monitoring/prometheus/prometheus.yml <<'PROMEOF'
    global:
      scrape_interval: 15s

    scrape_configs:

      # Prometheus monitors itself
      - job_name: "prometheus"
        static_configs:
          - targets:
              - "localhost:9090"

      # Automatically discover web EC2 instances
      - job_name: "web-node-exporter"
        ec2_sd_configs:
          - region: ${var.aws_region}
            port: 9100
            filters:
              - name: tag:Name
                values:
                  - "${var.project_name}-web"
              - name: instance-state-name
                values:
                  - "running"

      # Check whether the website responds over HTTP
      - job_name: "website-health"
        metrics_path: /probe

        params:
          module:
            - http_2xx

        static_configs:
          - targets:
              - "http://${aws_lb.web.dns_name}"

        relabel_configs:
          - source_labels:
              - __address__
            target_label: __param_target

          - source_labels:
              - __param_target
            target_label: instance

          - target_label: __address__
            replacement: "127.0.0.1:9115"

      # Automatically discover database EC2
      - job_name: "database"
        ec2_sd_configs:
          - region: ${var.aws_region}
            port: 9187
            filters:
              - name: tag:Name
                values:
                  - "${var.project_name}-database"
              - name: instance-state-name
                values:
                  - "running"

    PROMEOF

    # Create Blackbox Exporter configuration
    cat > /opt/monitoring/blackbox/blackbox.yml <<'BLACKBOXEOF'
    modules:
      http_2xx:
        prober: http
        timeout: 5s
    BLACKBOXEOF

    # Configure Grafana to use Prometheus
    cat > /opt/monitoring/grafana/provisioning/datasources/prometheus.yml <<'GRAFANAEOF'
    apiVersion: 1

    datasources:
      - name: Prometheus
        type: prometheus
        access: proxy
        url: http://127.0.0.1:9090
        isDefault: true
    GRAFANAEOF

    # Start Blackbox Exporter
    docker run -d \
      --name blackbox-exporter \
      --restart always \
      --network host \
      -v /opt/monitoring/blackbox/blackbox.yml:/config/blackbox.yml:ro \
      prom/blackbox-exporter:latest \
      --config.file=/config/blackbox.yml

    # Start Prometheus
    docker run -d \
      --name prometheus \
      --restart always \
      --network host \
      -v /opt/monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
      prom/prometheus:latest

    # Start Grafana
    docker run -d \
      --name grafana \
      --restart always \
      --network host \
      -v /opt/monitoring/grafana/provisioning:/etc/grafana/provisioning:ro \
      grafana/grafana:latest
  EOF

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-monitoring"
  }

  depends_on = [
    aws_route_table_association.monitoring_a
  ]
}