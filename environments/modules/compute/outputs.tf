# environments/modules/compute/outputs.tf

output "instance_id" {
  description = "ID de l'instance EC2"
  value       = aws_instance.wordpress.id
}

output "instance_public_ip" {
  description = "Adresse IP publique de l'instance EC2"
  value       = aws_instance.wordpress.public_ip
}

output "instance_private_ip" {
  description = "Adresse IP privée de l'instance EC2"
  value       = aws_instance.wordpress.private_ip
}