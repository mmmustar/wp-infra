# environments/modules/compute/variables.tf
variable "environment" {
  description = "Environment name (test/prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the instances will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instances will be created"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}