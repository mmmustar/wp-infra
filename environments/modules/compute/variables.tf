variable "environment" {
  description = "Environnement (test/prod)"
  type        = string
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "subnet_id" {
  description = "ID du sous-réseau où sera créée l'instance EC2"
  type        = string
}

variable "security_group_id" {
  description = "ID du groupe de sécurité pour l'instance EC2"
  type        = string
}

variable "ami_id" {
  description = "ID de l'AMI à utiliser pour l'instance EC2. Si vide, l'AMI Ubuntu le plus récent sera utilisé."
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

variable "root_volume_size" {
  description = "Taille du volume racine en Go"
  type        = number
}

variable "db_name" {
  description = "Nom de la base de données pour la configuration WordPress"
  type        = string
}

variable "db_username" {
  description = "Nom d'utilisateur de la base de données pour la configuration WordPress"
  type        = string
}

variable "db_password" {
  description = "Mot de passe de la base de données pour la configuration WordPress"
  type        = string
  sensitive   = true
}

variable "db_endpoint" {
  description = "Point de terminaison de la base de données pour la configuration WordPress"
  type        = string
}