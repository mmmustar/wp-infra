# environments/modules/compute/outputs.tf
output "instance_id" {
  description = "ID of the created EC2 instance"
  value       = aws_instance.wordpress.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = var.environment == "test" ? aws_eip.wordpress[0].public_ip : aws_instance.wordpress.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.wordpress.private_ip
}