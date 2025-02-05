output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.wordpress.public_ip
}

output "elastic_ip" {
  description = "Elastic IP associated with the instance"
  value       = var.elastic_ip_allocation_id
}
