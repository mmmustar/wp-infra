# environments/modules/compute/variables.tf

variable "environment" {
  description = "Environnement (test/prod)"
  type        = string
}

variable "project_name" {
  description = "Nom du projet pour le tagging des ressources"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC"
  type        = string
}

variable "subnet_id" {
  description = "ID du sous-réseau public"
  type        = string
}

variable "security_group_id" {
  description = "ID du groupe de sécurité"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
}

variable "ami_id" {
  description = "ID de l'AMI (laisser vide pour utiliser la dernière Ubuntu 20.04)"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Nom de la paire de clés SSH"
  type        = string
}

variable "instance_profile" {
  description = "Nom du profil d'instance IAM"
  type        = string
}

variable "root_volume_size" {
  description = "Taille du volume racine en Go"
  type        = number
}

variable "data_volume_size" {
  description = "Taille du volume de données en Go"
  type        = number
}

variable "eip_allocation_id" {
  description = "ID d'allocation de l'Elastic IP existante"
  type        = string
}
