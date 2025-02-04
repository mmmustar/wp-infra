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

variable "aws_region" {
  type    = string
  default = "eu-west-3"
}

variable "project_name" {
  type    = string
  default = "wordpress-mmustar"
}

variable "environment" {
  type    = string
  default = "test"
}

variable "vpc_cidr" {
  type    = string
  # Ex: "172.16.0.0/16" pour éviter la collision
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Liste des CIDR pour subnets publics"
  # Ex: ["172.16.1.0/24","172.16.2.0/24"]
  # On ne met pas de default si vous voulez tout paramétrer en haut
}
