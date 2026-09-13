# Innovatech AWS Infrastructure

This repository contains the infrastructure and documentation for the Innovatech Solutions study case.

## Technology Stack

- Cloud: AWS
- Infrastructure as Code: Terraform
- Compute: Amazon EC2
- Web Server: Nginx
- Containers: Docker
- Load Balancer: AWS Application Load Balancer
- Database: PostgreSQL running on a dedicated private EC2 instance
- Scaling: EC2 Auto Scaling Group
- Monitoring: Prometheus and Grafana (planned)
- CI/CD: GitHub Actions with a self-hosted runner (planned)
- Deployment Strategy: Rolling Deployment

## Infrastructure

The environment normally runs two EC2 web server instances and is configured with an Auto Scaling Group with a minimum of 2 and a maximum of 6 instances.

The infrastructure is distributed across two Availability Zones with separate:

- Public subnets
- Private web subnets
- Private database subnets

An internet-facing Application Load Balancer distributes HTTP traffic between the web servers.

The web servers run Nginx inside Docker containers and are deployed automatically using EC2 Launch Templates and Terraform.

The PostgreSQL database runs on a dedicated EC2 instance in a private database subnet. It has no public IP address and accepts PostgreSQL traffic only from the web server security group.

Database credentials are stored securely using AWS Systems Manager Parameter Store.

Administration of the private EC2 instances is performed using AWS Systems Manager Session Manager instead of public SSH access.

## Scaling

The web tier uses an EC2 Auto Scaling Group configured with:

- Minimum instances: 2
- Desired instances: 2
- Maximum instances: 6

A rolling instance refresh strategy is used when new versions of the Launch Template are deployed.

## Deployment Strategy

Rolling deployment is used for the web tier.

When the EC2 Launch Template changes, the Auto Scaling Group gradually replaces existing instances while maintaining application availability.

## Repository Structure

- `terraform/` - AWS Infrastructure as Code
- `docs/` - Design and project documentation
- `monitoring/` - Prometheus and Grafana configuration
- `application/` - Application files
- `.github/workflows/` - CI/CD pipelines