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

# Modules
module "network" {
  source              = "../modules/network"
  environment         = var.environment
  project_name        = var.project_name
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
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

  depends_on = [module.network]
}

# Existing EIP
data "aws_eip" "wordpress_test" {
  id = "eipalloc-0933b219497dd6c15"
}

# EC2 Instance
resource "aws_instance" "wordpress_test" {
  ami                         = "ami-06e02ae7bdac6b938"
  instance_type               = "t2.micro"
  subnet_id                   = module.network.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.wordpress_test.id]
  key_name                    = "test-aws-key-pair-new"
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 8
    volume_type          = "gp3"
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
    aws_security_group.wordpress_test
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

data "aws_db_instance" "wordpress" {
  db_instance_identifier = "wordpress-db"
}

# Outputs
output "rds_endpoint" {
  value = data.aws_db_instance.wordpress.endpoint
}

output "instance_public_ip" {
  value = aws_instance.wordpress_test.public_ip
}

output "instance_id" {
  value = aws_instance.wordpress_test.id
}

output "eip_public_ip" {
  value = data.aws_eip.wordpress_test.public_ip
}

output "ebs_csi_role_arn" {
  value = module.k3s.ebs_csi_role_arn
}