# environments/modules/elastic_ip/variables.tf

variable "environment" {
  description = "Environnement (test/prod)"
  type        = string
}

variable "project_name" {
  description = "Nom du projet pour le tagging des ressources"
  type        = string
}