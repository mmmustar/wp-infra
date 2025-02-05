data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Récupération des sous-réseaux RDS
data "aws_vpc" "rds_vpc" {
  id = "vpc-0385cddb5bd815883"
}

data "aws_subnets" "rds_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.rds_vpc.id]
  }
}

# Instance EC2 WordPress
resource "aws_instance" "wordpress" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [module.security.wordpress_sg_id]
  key_name      = var.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = "WP-Instance-Test"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Adresse IP élastique pour l'instance WordPress
resource "aws_eip" "wordpress" {
  count    = var.environment == "test" ? 1 : 0
  instance = aws_instance.wordpress.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-eip-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Module de sécurité
module "security" {
  source       = "../security"
  vpc_id       = var.vpc_id
  environment  = var.environment
  project_name = var.project_name
}
