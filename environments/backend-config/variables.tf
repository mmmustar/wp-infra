# environments/backend-config/variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "wordpress-mmustar"
}

variable "elastic_ip" {
  default = "35.180.222.29"
}


variable "elastic_ip_allocation_id" {
  description = "Existing Elastic IP allocation ID"
  default     = "eipalloc-0933b219497dd6c15"
}