# environments/prod/main.tf
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "wordpress-mmustar"
}

data "aws_secretsmanager_secret" "wp_secrets" {
  name = "book"
}

data "aws_secretsmanager_secret_version" "wp_secrets" {
  secret_id = data.aws_secretsmanager_secret.wp_secrets.id
}

data "aws_vpc" "existing" {
  id = "vpc-0385cddb5bd815883"
}

resource "aws_subnet" "compute" {
  vpc_id                  = data.aws_vpc.existing.id
  cidr_block              = "10.0.101.0/24"
  availability_zone       = "eu-west-3b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-compute-subnet-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

module "security" {
  source       = "../modules/security"
  environment  = var.environment
  project_name = var.project_name
  vpc_id       = data.aws_vpc.existing.id
}

module "compute" {
  source            = "../modules/compute"
  environment       = var.environment
  project_name      = var.project_name
  vpc_id            = data.aws_vpc.existing.id
  subnet_id         = aws_subnet.compute.id
  security_group_id = module.security.wordpress_sg_id
  instance_type     = "t3.medium"
  key_name          = "test-aws-key-pair-new"
}

resource "aws_eip_association" "wordpress_eip_assoc" {
  instance_id   = module.compute.instance_id
  allocation_id = "eipalloc-0efd7f176e6acc5cc"
}

data "aws_eips" "wordpress" {
  filter {
    name   = "allocation-id"
    values = ["eipalloc-0efd7f176e6acc5cc"]
  }
}

data "aws_db_instance" "wordpress" {
  db_instance_identifier = "wordpress-db"
}

resource "local_file" "secrets_json" {
  content  = jsonencode(jsondecode(data.aws_secretsmanager_secret_version.wp_secrets.secret_string))
  filename = "${path.module}/secrets.json"
}

resource "local_file" "ansible_inventory" {
  content = yamlencode({
    all = {
      children = {
        wordpress = {
          hosts = {
            "wp-prod" = {
              ansible_host = data.aws_eips.wordpress.public_ips[0]
              ansible_user = "ubuntu"
              ansible_ssh_private_key_file = "~/.ssh/test-aws-key-pair-new.pem"
              ansible_python_interpreter = "/usr/bin/python3"
            }
          }
        }
      }
    }
  })
  filename = "${path.module}/../../ansible/inventory/hosts_prod.yml"
}

output "rds_endpoint" {
  value = data.aws_db_instance.wordpress.endpoint
}

output "instance_public_ip" {
  value = module.compute.instance_public_ip
}

output "instance_id" {
  value = module.compute.instance_id
}

output "eip_public_ip" {
  value = data.aws_eips.wordpress.public_ips[0]
}

output "wordpress_db_secrets" {
  value     = jsondecode(data.aws_secretsmanager_secret_version.wp_secrets.secret_string)
  sensitive = true
}
