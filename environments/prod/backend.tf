# environments/prod/backend.tf
terraform {
  backend "s3" {
    bucket         = "wordpress-mmustar-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "wordpress-mmustar-terraform-locks"
    encrypt        = true
  }
}