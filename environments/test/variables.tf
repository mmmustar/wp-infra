variable "environment" {
  description = "Environnement"
  type        = string
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block pour le VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Liste des CIDR blocks pour les sous-réseaux publics"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Liste des CIDR blocks pour les sous-réseaux privés"
  type        = list(string)
}

variable "ami_id" {
  description = "ID de l'AMI à utiliser pour l'instance EC2"
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

variable "db_name" {
  description = "Nom de la base de données MySQL"
  type        = string
}

variable "db_username" {
  description = "Nom d'utilisateur pour la base de données"
  type        = string
}

variable "db_password" {
  description = "Mot de passe pour la base de données"
  type        = string
}

variable "db_allocated_storage" {
  description = "Taille de stockage allouée pour l'instance RDS (GB)"
  type        = number
}

variable "db_instance_class" {
  description = "Type d'instance pour l'instance RDS"
  type        = string
}

variable "eip_id" {
  description = "ID de l'EIP à utiliser. Laissez vide pour utiliser l'EIP créé automatiquement dans le module network."
  type        = string
}

variable "root_volume_size" {
  description = "Taille du volume racine en Go"
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

variable "db_parameter_group_name" {
  description = "Nom du groupe de paramètres pour l'instance RDS"
  type        = string
}

variable "db_skip_final_snapshot" {
  description = "Si true, aucun snapshot final ne sera créé lors de la suppression"
  type        = bool
}
