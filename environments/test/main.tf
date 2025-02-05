variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

module "network" {
  source       = "../modules/network"
  environment  = var.environment
  project_name = var.project_name
}

module "security" {
  source       = "../modules/security"
  environment  = var.environment
  project_name = var.project_name
  vpc_id       = module.network.vpc_id
}

module "compute" {
  source            = "../modules/compute"
  environment       = var.environment
  project_name      = var.project_name
  vpc_id            = module.network.vpc_id
  subnet_id         = module.network.public_subnet_ids[0]
  security_group_id = module.security.wordpress_sg_id
  instance_type     = "t3.medium"
  key_name          = "test-aws-key-pair-new"
}

# Association de l'Elastic IP à l'instance EC2
resource "aws_eip" "wordpress_eip" {
  domain     = "vpc"
}

resource "aws_eip_association" "wordpress_eip_assoc" {
  instance_id   = module.compute.instance_id
  allocation_id = aws_eip.wordpress_eip.id
}

# Utilisation de la base de données RDS existante
data "aws_db_instance" "wordpress" {
  db_instance_identifier = "wordpress-db"
}

output "rds_endpoint" {
  value = data.aws_db_instance.wordpress.endpoint
}

output "instance_public_ip" {
  value = module.compute.instance_public_ip
}

output "instance_id" {
  value = module.compute.instance_id
}

output "eip_public_ip" {
  value = aws_eip.wordpress_eip.public_ip
}
