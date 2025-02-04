# environments/test/variables.tf
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-3"
}

# SSH key pour instance EC2
variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "test-aws-key-pair-new" # Remplacez par votre nom de clé
}

variable "vpc_cidr" {
  description = "CIDR block pour le VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR des subnets publics"
  type        = list(string)
}

variable "rds_vpc_id" {
  description = "ID du VPC du RDS"
  type        = string
}

variable "rds_cidr_block" {
  description = "Plage CIDR du VPC RDS"
  type        = string
}

variable "rds_route_table_id" {
  description = "ID de la table de routage du VPC du RDS"
  type        = string
}

variable "rds_security_group_id" {
  description = "ID du Security Group du RDS"
  type        = string
}

variable "ec2_vpc_id" {
  description = "ID du VPC contenant l'EC2"
  type        = string
}

variable "ec2_cidr_block" {
  description = "CIDR block du VPC de l'EC2"
  type        = string
}

variable "route_table_id" {
  description = "ID de la table de routage du VPC de l'EC2"
  type        = string
}
