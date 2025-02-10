output "wordpress_sg_id" {
  description = "ID du Security Group de WordPress"
  value       = aws_security_group.wordpress.id
}