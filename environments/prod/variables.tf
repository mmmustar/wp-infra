variable "environment" {
  description = "Nom de l'environnement (test/prod)"
  type        = string
}

variable "project_name" {
  description = "Nom du projet pour le tagging"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC où sera créée l'instance EC2"
  type        = string
}

variable "subnet_id" {
  description = "ID du sous-réseau où sera créée l'instance EC2"
  type        = string
}

variable "security_group_id" {
  description = "Groupe de sécurité pour l'instance EC2"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Nom de la paire de clés SSH"
  type        = string
}

variable "ami_id" {
  description = "AMI ID utilisé pour l'instance EC2"
  type        = string
}

variable "eip_id" {
  description = "Elastic IP allocation ID"
  type        = string
}
