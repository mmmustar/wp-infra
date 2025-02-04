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
  description = "RDS VPC ID"
  type        = string
  default     = "vpc-0385cddb5bd815883" # Your existing RDS VPC ID
}

variable "rds_cidr_block" {
  description = "RDS VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16" # Adjust to match your RDS VPC CIDR
}

variable "rds_route_table_id" {
  description = "ID de la table de routage du VPC du RDS"
  type        = string
  default     = "rtb-0219653c2d8a675c9"
}

variable "rds_security_group_id" {
  description = "RDS Security Group ID"
  type        = string
  default     = "sg-00efe258e85b22a30" # Your existing RDS SG ID
}

variable "ec2_vpc_id" {
  description = "ID du VPC contenant l'EC2"
  type        = string
}

variable "ec2_cidr_block" {
  description = "CIDR block du VPC de l'EC2"
  type        = string
  default     = "172.16.0.0/16"
}


variable "route_table_id" {
  description = "ID de la table de routage du VPC de l'EC2"
  type        = string
}
