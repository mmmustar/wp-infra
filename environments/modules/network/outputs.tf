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

output "public_route_table_id" {
  description = "ID de la table de routage publique"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID de la table de routage privée"
  value       = aws_route_table.private.id
}