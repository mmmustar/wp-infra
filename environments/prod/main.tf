provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "wordpress-mmustar"
}

variable "eip_id" {
  description = "Elastic IP allocation ID"
  type        = string
  default     = "eipalloc-0efd7f176e6acc5cc"
}

# 🔹 Récupération des secrets depuis AWS Secrets Manager
data "aws_secretsmanager_secret" "wp_secrets" {
  name = "book"
}

data "aws_secretsmanager_secret_version" "wp_secrets" {
  secret_id = data.aws_secretsmanager_secret.wp_secrets.id
}

resource "local_file" "secrets_json" {
  content  = jsonencode(jsondecode(data.aws_secretsmanager_secret_version.wp_secrets.secret_string))
  filename = "${path.module}/secrets.json"
}

# 🔹 Sélection du VPC existant
data "aws_vpc" "existing" {
  id = "vpc-0385cddb5bd815883"
}

# 🔹 Création d'un sous-réseau pour la compute instance
resource "aws_subnet" "compute" {
  vpc_id                  = data.aws_vpc.existing.id
  cidr_block              = "10.0.101.0/24"
  availability_zone       = "eu-west-3b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-compute-subnet-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# 🔹 Déploiement des modules de sécurité
module "security" {
  source       = "../modules/security"
  environment  = var.environment
  project_name = var.project_name
  vpc_id       = data.aws_vpc.existing.id
}

# 🔹 Déploiement de l'instance EC2
module "compute" {
  source            = "../modules/compute"
  environment       = var.environment
  project_name      = var.project_name
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  security_group_id = var.security_group_id
  instance_type     = var.instance_type
  key_name          = var.key_name
  ami_id            = data.aws_ami.ubuntu.id  
  aws_account_id    = "730335289383"
}


# 🔹 Association de l'Elastic IP à l'instance EC2
resource "aws_eip_association" "wordpress_eip_assoc" {
  instance_id   = module.compute.instance_id
  allocation_id = var.eip_id
}

# 🔹 Outputs
output "instance_id" {
  description = "ID de l'instance EC2"
  value       = module.compute.instance_id
}

output "instance_public_ip" {
  description = "Adresse IP publique de l'EC2"
  value       = module.compute.instance_public_ip
}

output "eip_public_ip" {
  description = "Adresse IP de l'Elastic IP"
  value       = var.eip_id
}
