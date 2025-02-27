# environments/modules/network/outputs.tf

output "vpc_id" {
  description = "ID du VPC créé"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs des sous-réseaux publics"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs des sous-réseaux privés"
  value       = aws_subnet.private[*].id
}

output "wordpress_sg_id" {
  description = "ID du groupe de sécurité pour l'instance EC2"
  value       = aws_security_group.wordpress.id
}

output "db_sg_id" {
  description = "ID du groupe de sécurité pour la base de données RDS"
  value       = aws_security_group.db.id
}

output "eip_id" {
  description = "ID de l'Elastic IP"
  value       = aws_eip.wordpress.id
}

output "eip_public_ip" {
  description = "Adresse IP publique de l'Elastic IP"
  value       = aws_eip.wordpress.public_ip
}