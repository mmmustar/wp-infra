# environments/modules/security/variables.tf

variable "vpc_id" {
  description = "ID du VPC où créer les groupes de sécurité"
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

variable "ssh_allowed_ips" {
  description = "Liste des CIDR blocks autorisés à se connecter en SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # À modifier pour limiter l'accès
}

variable "cloudflare_ip_ranges" {
  description = "Plages d'IP Cloudflare"
  type        = list(string)
  default     = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22", 
    "103.31.4.0/22", 
    "141.101.64.0/18", 
    "108.162.192.0/18",
    "190.93.240.0/20", 
    "188.114.96.0/20", 
    "197.234.240.0/22", 
    "198.41.128.0/17", 
    "162.158.0.0/15", 
    "104.16.0.0/13"
  ]
}