# environments/test/outputs.tf

# Outputs réseau
output "vpc_id" {
  description = "ID du VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs des sous-réseaux publics"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs des sous-réseaux privés"
  value       = module.network.private_subnet_ids
}

# Outputs EIP
output "elastic_ip_id" {
  description = "ID de l'Elastic IP (à utiliser dans les déploiements futurs)"
  value       = module.elastic_ip.eip_id
}

output "elastic_ip_public_ip" {
  description = "Adresse IP publique de l'Elastic IP"
  value       = module.elastic_ip.eip_public_ip
}

output "elastic_ip_allocation_id" {
  description = "Allocation ID de l'Elastic IP (à utiliser dans les déploiements futurs)"
  value       = module.elastic_ip.eip_allocation_id
}

# Outputs security
output "wordpress_sg_id" {
  description = "ID du groupe de sécurité WordPress"
  value       = module.security.wordpress_sg_id
}

output "database_sg_id" {
  description = "ID du groupe de sécurité de la base de données"
  value       = module.security.database_sg_id
}

# Outputs compute
output "instance_id" {
  description = "ID de l'instance EC2"
  value       = module.compute.instance_id
}

output "instance_public_ip" {
  description = "Adresse IP publique de l'instance EC2"
  value       = module.compute.instance_public_ip
}

output "instance_private_ip" {
  description = "Adresse IP privée de l'instance EC2"
  value       = module.compute.instance_private_ip
}

output "data_volume_id" {
  description = "ID du volume de données EBS"
  value       = module.compute.data_volume_id
}

# Outputs database
output "db_instance_endpoint" {
  description = "Endpoint de connexion à la base de données"
  value       = module.database.db_instance_endpoint
}

output "db_name" {
  description = "Nom de la base de données"
  value       = module.database.db_instance_name
}

output "db_username" {
  description = "Nom d'utilisateur de la base de données"
  value       = module.database.db_instance_username
}

# Output des secrets
output "wordpress_config_secret_arn" {
  description = "ARN du secret contenant la configuration WordPress"
  value       = aws_secretsmanager_secret.wordpress_config.arn
}

# Output des URLs (dynamiques, basées sur les variables)

output "wordpress_url" {
  description = "URL du site WordPress"
  value       = "https://${var.wordpress_domain}"
}

output "wordpress_admin_url" {
  description = "URL d'administration WordPress"
  value       = "https://${var.wordpress_domain}/wp-admin"
}