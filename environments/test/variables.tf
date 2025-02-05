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
  default     = "test-aws-key-pair-new"  # Remplacez par votre nom de clé
  
}

variable "existing_rds_sg_id" {
  description = "Security Group ID of existing RDS"
  type        = string
}

variable "existing_rds_id" {
  description = "Existing RDS instance ID"
  type        = string
}

variable "existing_vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "existing_subnet_id" {
  description = "ID of the existing subnet"
  type        = string
}

variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t3.medium"
}

variable "elastic_ip_allocation_id" {
  description = "Allocation ID of the Elastic IP"
  type        = string
}
