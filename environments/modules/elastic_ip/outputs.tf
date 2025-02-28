# environments/modules/elastic_ip/outputs.tf

output "eip_id" {
  description = "ID de l'Elastic IP"
  value       = aws_eip.wordpress.id
}

output "eip_public_ip" {
  description = "Adresse IP publique de l'Elastic IP"
  value       = aws_eip.wordpress.public_ip
}

output "eip_allocation_id" {
  description = "ID d'allocation de l'Elastic IP"
  value       = aws_eip.wordpress.allocation_id
}