resource "aws_instance" "database" {
  ami           = data.aws_ssm_parameter.amazon_linux.value
  instance_type = "t3.micro"

  iam_instance_profile = aws_iam_instance_profile.ec2_ssm.name

  subnet_id = aws_subnet.db_a.id

  vpc_security_group_ids = [
    aws_security_group.db.id
  ]

  associate_public_ip_address = false

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash

    dnf install -y postgresql15-server postgresql15

    postgresql-setup --initdb --unit postgresql

    echo "listen_addresses = '*'" >> /var/lib/pgsql/data/postgresql.conf

    echo "host all all 10.0.10.0/24 scram-sha-256" >> /var/lib/pgsql/data/pg_hba.conf
    echo "host all all 10.0.11.0/24 scram-sha-256" >> /var/lib/pgsql/data/pg_hba.conf

    systemctl enable postgresql
    systemctl start postgresql

    sudo -u postgres psql -c "CREATE DATABASE innovatech;"
  EOF

  tags = {
    Name = "${var.project_name}-database"
  }
}