terraform {
  backend "s3" {}  # Assure-toi que ce fichier ne duplique pas backend.tf
}

# 🔹 Sélection de l'AMI Ubuntu 20.04 LTS
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# 🔹 Déploiement du module Compute (EC2)
module "compute" {
  source            = "../modules/compute"
  environment       = var.environment
  project_name      = var.project_name
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  security_group_id = var.security_group_id
  instance_type     = var.instance_type
  key_name          = var.key_name
  ami_id            = data.aws_ami.ubuntu.id  # ✅ Correction
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
