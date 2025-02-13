variable "db_subnet_ids" {
  description = "Liste des IDs des sous-réseaux pour le DB Subnet Group"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID du VPC où sera créé l'instance"
  type        = string
}

variable "environment" {
  description = "Environnement (prod)"
  type        = string
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
}

variable "key_name" {
  description = "Nom de la paire de clés SSH"
  type        = string
}

variable "ami_id" {
  description = "AMI ID utilisé pour l'instance EC2"
  type        = string
}

variable "security_group_id" {
  description = "ID du groupe de sécurité pour l'instance EC2"
  type        = string
}

variable "eip_id" {
  description = "Allocation ID de l'EIP"
  type        = string
}
