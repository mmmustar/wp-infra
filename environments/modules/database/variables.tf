variable "environment" {
  description = "Environnement (test/prod)"
  type        = string
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "subnet_ids" {
  description = "Liste des IDs des sous-réseaux pour le groupe de sous-réseaux DB"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID du groupe de sécurité pour la base de données"
  type        = string
}

variable "db_allocated_storage" {
  description = "Taille de stockage allouée pour l'instance RDS (GB)"
  type        = number
}

variable "db_storage_type" {
  description = "Type de stockage pour l'instance RDS"
  type        = string
}

variable "db_engine_version" {
  description = "Version du moteur MySQL pour l'instance RDS"
  type        = string
}

variable "db_instance_class" {
  description = "Type d'instance pour l'instance RDS"
  type        = string
}

variable "db_name" {
  description = "Nom de la base de données"
  type        = string
}

variable "db_username" {
  description = "Nom d'utilisateur pour la base de données"
  type        = string
}

variable "db_password" {
  description = "Mot de passe pour la base de données"
  type        = string
  sensitive   = true
}

variable "db_parameter_group_name" {
  description = "Nom du groupe de paramètres pour l'instance RDS"
  type        = string
}

variable "db_skip_final_snapshot" {
  description = "Si true, aucun snapshot final ne sera créé lors de la suppression"
  type        = bool
}
