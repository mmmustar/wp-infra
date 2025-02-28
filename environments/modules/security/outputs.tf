# environments/modules/security/outputs.tf

output "wordpress_sg_id" {
  description = "ID du groupe de sécurité WordPress"
  value       = aws_security_group.wordpress.id
}

output "database_sg_id" {
  description = "ID du groupe de sécurité de la base de données"
  value       = aws_security_group.database.id
}

output "ec2_instance_profile_name" {
  description = "Nom du profil d'instance EC2"
  value       = aws_iam_instance_profile.ec2_wordpress_profile.name
}

output "ec2_instance_profile_arn" {
  description = "ARN du profil d'instance EC2"
  value       = aws_iam_instance_profile.ec2_wordpress_profile.arn
}

output "wordpress_role_name" {
  description = "Nom du rôle IAM pour WordPress"
  value       = aws_iam_role.ec2_wordpress_role.name
}
