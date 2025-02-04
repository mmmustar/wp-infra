# Provider configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = "eu-west-3"
}

# Variables
variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment for deployment"
  type        = string
}

# Modules (Correction des chemins)
module "network" {
  source              = "../modules/network"
  environment         = var.environment
  project_name        = var.project_name
  vpc_cidr            = var.ec2_cidr_block
  public_subnet_cidrs = ["172.16.1.0/24", "172.16.2.0/24"]
  
  rds_vpc_id            = var.rds_vpc_id
  rds_cidr_block        = var.rds_cidr_block
  ec2_vpc_id            = module.network.vpc_id
  ec2_cidr_block        = var.ec2_cidr_block
  rds_route_table_id    = var.rds_route_table_id
  rds_security_group_id = data.aws_security_group.rds.id
  route_table_id        = module.network.route_table_id
}

module "k3s" {
  source      = "../modules/k3s"
  environment = var.environment
}

# Security Group
resource "aws_security_group" "wordpress_test" {
  name_prefix = "WP-SecurityGroup-Test-"
  description = "Security group for WordPress test instance"
  vpc_id      = module.network.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "WP-SG-Test"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Existing EIP
data "aws_eip" "wordpress_test" {
  id = "eipalloc-0933b219497dd6c15"
}

# Data source pour le rôle IAM existant
data "aws_iam_role" "ec2_secrets_manager_role" {
  name = "EC2SecretsManagerRole"
}

# IAM Instance Profile pour EC2
resource "aws_iam_instance_profile" "ec2_secrets_manager_profile" {
  name = "ec2-secrets-manager-profile"
  role = data.aws_iam_role.ec2_secrets_manager_role.name
}

# EC2 Instance (Correction pour SSH et connexion réseau)
resource "aws_instance" "wordpress_test" {
  ami                         = "ami-06e02ae7bdac6b938"
  instance_type               = "t3.medium"
  subnet_id                   = module.network.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.wordpress_test.id]
  key_name                    = "test-aws-key-pair-new"
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_secrets_manager_profile.name

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y openssh-server
              sudo systemctl enable ssh
              sudo systemctl start ssh
              EOF

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "WP-Instance-Test"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    module.network,
    aws_security_group.wordpress_test,
    aws_iam_instance_profile.ec2_secrets_manager_profile
  ]
}

# EIP Association
resource "aws_eip_association" "wordpress_test" {
  instance_id   = aws_instance.wordpress_test.id
  allocation_id = data.aws_eip.wordpress_test.id
  depends_on    = [aws_instance.wordpress_test]
}

# RDS Security Group and Instance data sources
data "aws_security_group" "rds" {
  id = "sg-00efe258e85b22a30"
}

# Define the RDS instance data source
data "aws_db_instance" "wordpress" {
  db_instance_identifier = "wordpress-db"
}