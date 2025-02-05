output "instance_public_ip" {
  description = "IP publique de l'instance EC2"
  value       = module.compute.instance_public_ip
}

output "elastic_ip" {
  description = "Elastic IP associée à l'instance"
  value       = "35.180.222.29"
}