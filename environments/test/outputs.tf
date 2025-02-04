output "rds_endpoint" {
  value = data.aws_db_instance.wordpress.endpoint
}

output "instance_public_ip" {
  value = aws_instance.wordpress_test.public_ip
}

output "instance_id" {
  value = aws_instance.wordpress_test.id
}

output "eip_public_ip" {
  value = data.aws_eip.wordpress_test.public_ip
}

output "ebs_csi_role_arn" {
  value = module.k3s.ebs_csi_role_arn
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}