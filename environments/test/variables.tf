# environments/test/variables.tf
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "wordpress-mmustar"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "test"
}

# SSH key pour instance EC2
variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "wp-key-test" # A adapter selon votre clé SSH
}
