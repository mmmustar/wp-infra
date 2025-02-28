# environments/modules/compute/outputs.tf

output "instance_id" {
  description = "ID de l'instance EC2"
  value       = aws_instance.wordpress.id
}

output "instance_private_ip" {
  description = "Adresse IP privée de l'instance"
  value       = aws_instance.wordpress.private_ip
}

output "instance_public_ip" {
  description = "Adresse IP publique de l'instance (via l'EIP associée)"
  value       = aws_eip_association.wordpress.public_ip
}

output "data_volume_id" {
  description = "ID du volume de données EBS"
  value       = aws_ebs_volume.wordpress_data.id
}