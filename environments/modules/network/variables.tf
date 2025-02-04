variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "environment" {
  description = "Environnement (test, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block du VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR des subnets publics"
  type        = list(string)
}

variable "rds_vpc_id" {
  description = "ID du VPC contenant le RDS"
  type        = string
}

variable "rds_cidr_block" {
  description = "Plage CIDR du VPC RDS"
  type        = string
}

variable "rds_route_table_id" {
  description = "ID de la table de routage du VPC contenant le RDS"
  type        = string
}

variable "rds_security_group_id" {
  description = "ID du Security Group du RDS"
  type        = string
}

variable "ec2_vpc_id" {
  description = "ID du VPC de l'EC2"
  type        = string
}

variable "ec2_cidr_block" {
  description = "Plage CIDR du VPC de l'EC2"
  type        = string
}

variable "route_table_id" {
  description = "ID de la table de routage du VPC de l'EC2"
  type        = string
}
