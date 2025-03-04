variable "environment" {
  description = "Environnement (test/prod/verif)"
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
  description = "ID du sous-réseau (public pour accès facile aux dashboards)"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.small"
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
  description = "Nom du profil d'instance IAM pour l'instance de monitoring"
  type        = string
}

variable "root_volume_size" {
  description = "Taille du volume racine en Go"
  type        = number
  default     = 20
}

variable "data_volume_size" {
  description = "Taille du volume de données pour Prometheus/Grafana en Go"
  type        = number
  default     = 30
}

variable "ssh_allowed_ips" {
  description = "Liste des CIDR autorisés pour SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
