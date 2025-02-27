# environments/modules/database/outputs.tf

output "db_instance_id" {
  description = "ID de l'instance RDS"
  value       = aws_db_instance.wordpress.id
}

output "db_instance_endpoint" {
  description = "Point de terminaison de connexion de l'instance RDS"
  value       = aws_db_instance.wordpress.endpoint
}

output "db_instance_name" {
  description = "Nom de la base de données"
  value       = aws_db_instance.wordpress.db_name
}

output "db_instance_username" {
  description = "Nom d'utilisateur de la base de données"
  value       = aws_db_instance.wordpress.username
}