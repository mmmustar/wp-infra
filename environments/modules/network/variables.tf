# environments/modules/network/variables.tf
variable "environment" {
  description = "Environment name (test/prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "wordpress-mmustar"
}

# environments/modules/network/variables.tf
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "172.16.0.0/16"  # Modifié pour éviter le conflit avec le RDS VPC
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["172.16.1.0/24", "172.16.2.0/24"]  # Ajusté en conséquence
}