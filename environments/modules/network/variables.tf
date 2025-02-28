# environments/modules/network/variables.tf

variable "environment" {
  description = "Environnement (test/prod)"
  type        = string
}

variable "project_name" {
  description = "Nom du projet pour le tagging des ressources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block pour le VPC"
  type        = string
  default     = "172.16.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Liste des CIDR blocks pour les sous-réseaux publics"
  type        = list(string)
  default     = ["172.16.1.0/24", "172.16.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Liste des CIDR blocks pour les sous-réseaux privés"
  type        = list(string)
  default     = ["172.16.3.0/24", "172.16.4.0/24"]
}