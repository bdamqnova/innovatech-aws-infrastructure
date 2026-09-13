resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Week 2 implementation:
# - Internet Gateway
# - Public subnets
# - Private web subnets
# - Private database subnets
# - Security groups
# - Application Load Balancer
# - EC2 Auto Scaling Group
# - RDS PostgreSQL
# - Monitoring infrastructure