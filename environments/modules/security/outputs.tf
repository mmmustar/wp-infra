# environments/modules/security/outputs.tf
output "wordpress_sg_id" {
  description = "ID of WordPress security group"
  value       = aws_security_group.wordpress.id
}

output "rds_sg_id" {
  description = "ID of RDS security group"
  value       = aws_security_group.rds.id
}