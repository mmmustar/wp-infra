// environments/test/main.tf

// Variables de déploiement (environnement et projet)
variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

// Récupération du VPC existant (WP-VPC)
data "aws_vpc" "existing" {
  id = "vpc-0385cddb5bd815883"
}

// Création d'un nouveau sous-réseau dédié aux instances EC2 dans le VPC existant
resource "aws_subnet" "compute" {
  vpc_id                  = data.aws_vpc.existing.id
  cidr_block              = "10.0.100.0/24"  # Doit être un sous-ensemble du VPC (par exemple, si le VPC est en 10.0.0.0/16)
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-compute-subnet-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

// Appel du module Security en lui passant le VPC existant
module "security" {
  source       = "../modules/security"
  environment  = var.environment
  project_name = var.project_name
  vpc_id       = data.aws_vpc.existing.id
}

// Appel du module Compute en lui passant le VPC existant et le sous-réseau créé ci-dessus
module "compute" {
  source            = "../modules/compute"
  environment       = var.environment
  project_name      = var.project_name
  vpc_id            = data.aws_vpc.existing.id
  subnet_id         = aws_subnet.compute.id
  security_group_id = module.security.wordpress_sg_id
  instance_type     = "t3.medium"
  key_name          = "test-aws-key-pair-new"
}

// Association de l'EIP existante à l'instance EC2
resource "aws_eip_association" "wordpress_eip_assoc" {
  instance_id   = module.compute.instance_id
  allocation_id = "eipalloc-0933b219497dd6c15"  // Utilise l'EIP existante
}

// Récupération de l'EIP existante via un data source
data "aws_eips" "wordpress" {
  filter {
    name   = "allocation-id"
    values = ["eipalloc-0933b219497dd6c15"]
  }
}

// Utilisation de la base de données RDS existante
data "aws_db_instance" "wordpress" {
  db_instance_identifier = "wordpress-db"
}

// Exports
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
  description = "Public IP of the associated existing EIP"
  value       = data.aws_eips.wordpress.public_ips[0]
}
