############################################################
# environments/test/main.tf
############################################################
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
  region = var.aws_region
}

############################################################
# RÉUTILISER LE VPC EXISTANT
#
# On suppose que vous avez déjà :
#   - vpc-0385cddb5bd815883  (VPC existant)
#   - un ou deux subnets (publics ou privés) 
#     ex: subnet-07dfe7a7cdcb5036e, subnet-085d8f8361978d689
#
# Ici, on va juste pointer sur un Subnet existant (public)
############################################################

# Donnée ou variable : ID du VPC existant
data "aws_vpc" "existing" {
  id = var.existing_vpc_id
}

# Donnée ou variable : un Subnet (public) existant dans ce VPC
# => Remplacez par votre subnet réellement accessible
data "aws_subnet" "public" {
  id = var.existing_subnet_id
}

############################################################
# Sécurité : on définit (ou réutilise) un SG
# Ici, on crée un nouveau SG "wordpress_test_sg" 
# dans le VPC existant, qui autorise HTTP, HTTPS, SSH...
############################################################
resource "aws_security_group" "wordpress_test_sg" {
  name        = "wordpress-test-sg"
  description = "Security group for WordPress test instance"
  vpc_id      = data.aws_vpc.existing.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Sortie illimitée
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "wordpress-test-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

############################################################
# EC2 Instance (WordPress / K3s node)
############################################################
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "wordpress_test" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.public.id  # Subnet existant
  vpc_security_group_ids = [aws_security_group.wordpress_test_sg.id]
  key_name               = var.key_name

  associate_public_ip_address = true  # si c'est un subnet public

  # Ex: user_data minimal pour SSH
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y openssh-server
              sudo systemctl enable ssh
              sudo systemctl start ssh
              EOF

  root_block_device {
    volume_size           = 10
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
}

############################################################
# (Facultatif) Associer un EIP si besoin
############################################################
# data "aws_eip" "existing_eip" {
#   id = "eipalloc-xxxxxxxxxxx"
# }

# resource "aws_eip_association" "wordpress_eip" {
#   instance_id   = aws_instance.wordpress_test.id
#   allocation_id = data.aws_eip.existing_eip.id
# }

############################################################
# Data source pour RDS existant, si besoin
############################################################
data "aws_security_group" "rds" {
  id = var.existing_rds_sg_id  # ex: sg-00efe258e85b22a30
}

data "aws_db_instance" "rds" {
  db_instance_identifier = var.existing_rds_id  # ex: "wordpress-db"
}

output "rds_endpoint" {
  description = "Endpoint RDS existant"
  value       = data.aws_db_instance.rds.endpoint
}

############################################################
# Outputs standard
############################################################
output "instance_id" {
  description = "ID of EC2"
  value       = aws_instance.wordpress_test.id
}

output "public_ip" {
  description = "Public IP of EC2"
  value       = aws_instance.wordpress_test.public_ip
}
