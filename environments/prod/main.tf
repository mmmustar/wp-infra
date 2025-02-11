data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  // Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

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

# 🔹 Déploiement du module Compute
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
}

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
