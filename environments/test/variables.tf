######################################################
# environments/test/variables.tf
######################################################
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "wordpress-mmustar"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "test"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "test-aws-key-pair-new"
}

# VPC et Subnet existants
variable "existing_vpc_id" {
  description = "ID du VPC existant où on déploie l'EC2"
  type        = string
}

variable "existing_subnet_id" {
  description = "Subnet ID (public ou privé) dans ce VPC"
  type        = string
}

variable "existing_rds_sg_id" {
  description = "Security Group ID du RDS (si besoin de référence)"
  type        = string
  default     = "sg-00efe258e85b22a30"
}

variable "existing_rds_id" {
  description = "DB Instance identifier du RDS"
  type        = string
  default     = "wordpress-db"
}
