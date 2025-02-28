# environments/modules/database/variables.tf

variable "environment" {
  description = "Environnement (test/prod)"
  type        = string
}

variable "project_name" {
  description = "Nom du projet pour le tagging des ressources"
  type        = string
}

variable "subnet_ids" {
  description = "IDs des sous-réseaux pour le groupe de sous-réseaux RDS"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID du groupe de sécurité pour la base de données"
  type        = string
}

variable "allocated_storage" {
  description = "Taille de stockage allouée en Go"
  type        = number
  default     = 20
}

variable "instance_class" {
  description = "Classe d'instance RDS"
  type        = string
  default     = "db.t3.small"
}

variable "database_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "wordpress"
}

variable "database_username" {
  description = "Nom d'utilisateur de la base de données"
  type        = string
  default     = "wordpress"
}

variable "database_password" {
  description = "Mot de passe de la base de données"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Activer le multi-AZ pour la haute disponibilité"
  type        = bool
  default     = false
}
