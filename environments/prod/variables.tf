# environments/prod/variables.tf
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-3"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "test-aws-key-pair-new"
}