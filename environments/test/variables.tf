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
