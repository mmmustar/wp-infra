# environments/modules/network/outputs.tf

output "vpc_id" {
  value = aws_vpc.main.id
}

# Ajustement pour retourner un tableau des deux subnets créés
output "public_subnet_ids" {
  description = "Liste des subnets publics"
  value = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]
}

output "route_table_id" {
  value = aws_route_table.public.id
}
