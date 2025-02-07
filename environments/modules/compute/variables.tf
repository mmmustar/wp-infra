variable "environment" {
  description = "Environment name (test/prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EC2 instance will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the EC2 instance will be created"
  type        = string
}

variable "security_group_id" {
  description = "Security Group for the EC2 instance"
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

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}
