# environments/modules/network/outputs.tf

output "vpc_id" {
  description = "ID du VPC principal"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Liste des subnets publics"
  value       = [for s in aws_subnet.public : s.id]
}

output "route_table_id" {
  description = "ID de la route table publique"
  value       = aws_route_table.public.id
}
