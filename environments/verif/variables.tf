# environments/test/variables.tf

# Variables générales
variable "aws_region" {
  description = "Région AWS où déployer les ressources"
  type        = string
}

variable "environment" {
  description = "Environnement (test/prod)"
  type        = string
}

variable "project_name" {
  description = "Nom du projet pour le tagging des ressources"
  type        = string
}

# Variables réseau
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

# Variables EIP
variable "eip_allocation_id" {
  description = "ID d'allocation de l'Elastic IP existante"
  type        = string
}

# Variables base de données
variable "db_allocated_storage" {
  description = "Taille de stockage allouée pour RDS en Go"
  type        = number
}

variable "db_instance_class" {
  description = "Classe d'instance RDS"
  type        = string
}

variable "db_name" {
  description = "Nom de la base de données"
  type        = string
}

variable "db_username" {
  description = "Nom d'utilisateur de la base de données"
  type        = string
}

variable "db_password" {
  description = "Mot de passe de la base de données"
  type        = string
  sensitive   = true
}

variable "db_multi_az" {
  description = "Activer le multi-AZ pour la haute disponibilité"
  type        = bool
  default     = false
}

# Variables Compute
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

variable "data_volume_size" {
  description = "Taille du volume de données en Go"
  type        = number
}

variable "ami_id" {
  description = "ID de l'AMI pour l'instance EC2 (vide = dernière Ubuntu 20.04)"
  type        = string
  default     = ""
}

variable "wordpress_domain" {
  description = "Nom de domaine pour le site WordPress"
  type        = string
}

variable "ssh_allowed_ips" {
  description = "Liste des CIDR autorisés pour SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}