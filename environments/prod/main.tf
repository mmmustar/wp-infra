data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  // Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

data "aws_secretsmanager_secret" "wp_secrets" {
  name = "book"
}

data "aws_secretsmanager_secret_version" "wp_secrets" {
  secret_id = data.aws_secretsmanager_secret.wp_secrets.id
}

resource "local_file" "secrets_json" {
  content  = jsonencode(jsondecode(data.aws_secretsmanager_secret_version.wp_secrets.secret_string))
  filename = "${path.module}/secrets.json"
}

locals {
  db_secrets = jsondecode(data.aws_secretsmanager_secret_version.wp_secrets.secret_string)
}

resource "aws_db_subnet_group" "wordpress_db_subnet_group" {
  name       = "wordpress-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "WordPress DB Subnet Group"
  }
}

resource "aws_security_group" "wordpress_db_sg" {
  name        = "wordpress-db-sg"
  description = "Groupe de securite pour RDS"  // Sans accent
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "wordpress_db" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  db_name                = local.db_secrets.MYSQL_DATABASE
  username               = local.db_secrets.MYSQL_USER
  password               = local.db_secrets.MYSQL_PASSWORD
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true

  db_subnet_group_name   = aws_db_subnet_group.wordpress_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.wordpress_db_sg.id]

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [allocated_storage, engine_version, instance_class]
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

module "compute" {
  source            = "../modules/compute"
  environment       = var.environment
  project_name      = var.project_name
  vpc_id            = var.vpc_id
  subnet_id         = var.db_subnet_ids[0]   // Utilise le premier sous-réseau
  security_group_id = var.security_group_id
  instance_type     = var.instance_type
  key_name          = var.key_name
  ami_id            = var.ami_id
}

resource "aws_eip_association" "wordpress_eip_assoc" {
  instance_id   = module.compute.instance_id
  allocation_id = var.eip_id
}

output "instance_id" {
  description = "ID de l'instance EC2"
  value       = module.compute.instance_id
}

output "instance_public_ip" {
  description = "Adresse IP publique de l'EC2"
  value       = module.compute.instance_public_ip
}
