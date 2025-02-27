output "vpc_id" {
  description = "ID du VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs des sous-réseaux publics"
  value       = module.network.public_subnet_ids
}

output "wordpress_public_ip" {
  description = "Adresse IP publique de l'instance WordPress"
  value       = module.network.eip_public_ip
}

output "wordpress_url" {
  description = "URL du site WordPress"
  value       = "http://${module.network.eip_public_ip}"
}

output "rds_endpoint" {
  description = "Point de terminaison de la base de données RDS"
  value       = module.database.db_instance_endpoint
}
