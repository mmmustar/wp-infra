# environments/backend-config/outputs.tf
output "bucket_name" {
  description = "Nom du bucket S3 pour le state Terraform"
  value       = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table_name" {
  description = "Nom de la table DynamoDB pour le verrouillage"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "instance_ip" {
  value = aws_instance.wordpress.public_ip
}

output "elastic_ip" {
  value = aws_eip.wordpress_eip.public_ip
}

output "elastic_ip_association" {
  value = aws_eip_association.wordpress_eip_assoc.allocation_id
}