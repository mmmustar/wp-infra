# environments/modules/monitoring/outputs.tf

output "instance_id" {
  description = "ID de l'instance de monitoring"
  value       = aws_instance.monitoring.id
}

output "instance_private_ip" {
  description = "Adresse IP privée de l'instance de monitoring"
  value       = aws_instance.monitoring.private_ip
}

output "instance_public_ip" {
  description = "Adresse IP publique de l'instance de monitoring"
  value       = aws_eip.monitoring.public_ip
}

output "data_volume_id" {
  description = "ID du volume de données EBS pour Prometheus/Grafana"
  value       = aws_ebs_volume.monitoring_data.id
}

output "eip_allocation_id" {
  description = "ID d'allocation de l'Elastic IP"
  value       = aws_eip.monitoring.id
}