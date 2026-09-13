data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-"
  image_id      = data.aws_ssm_parameter.amazon_linux.value
  instance_type = "t3.small"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm.name
  }

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y docker

    systemctl enable docker
    systemctl start docker

    mkdir -p /opt/innovatech

    echo "<h1>Innovatech</h1><p>Server: $(hostname)</p>" > /opt/innovatech/index.html

    docker run -d \
      --name nginx \
      --restart always \
      -p 80:80 \
      -v /opt/innovatech:/usr/share/nginx/html:ro \
      nginx:latest
  EOF
  )
}