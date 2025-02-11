/*
 * Module Compute : Déploiement d'une instance EC2 WordPress
 * avec création du rôle IAM, de sa policy et de l'instance profile associés.
 */

//////////////////////////////
// 🔹 Sélection de l'AMI Ubuntu 20.04 LTS
//////////////////////////////
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  // Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

//////////////////////////////
// 🔹 Création du rôle IAM pour EC2
//////////////////////////////
resource "aws_iam_role" "ec2_wordpress_role" {
  name = "EC2-WordPress-Access-${var.environment}"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

//////////////////////////////
// 🔹 Création de la policy IAM pour accéder à Secrets Manager
//////////////////////////////resource "aws_iam_policy" "secrets_manager_read" {
resource "aws_iam_policy" "secrets_manager_read" {
  name        = "EC2SecretsManagerReadOnly-${var.environment}"
  description = "Permission de lecture seule sur AWS Secrets Manager"
  policy      = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action   = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

//////////////////////////////
// 🔹 Attachement de la policy IAM au rôle EC2
//////////////////////////////
resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.ec2_wordpress_role.name  
  policy_arn = aws_iam_policy.secrets_manager_read.arn
}

//////////////////////////////
// 🔹 Création du profile IAM pour l'instance EC2
//////////////////////////////
resource "aws_iam_instance_profile" "ec2_wordpress_profile" {
  name = "EC2WordPressProfile-${var.environment}"
  role = aws_iam_role.ec2_wordpress_role.name
}

//////////////////////////////
// 🔹 Création de l'instance EC2 WordPress
//////////////////////////////
resource "aws_instance" "wordpress" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_wordpress_profile.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.project_name}-instance-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

// 🔹 Création du rôle IAM pour l'EC2
resource "aws_iam_role" "ec2_wordpress_role" {
  name = "EC2-WordPress-Access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

// 🔹 Attachement de la politique IAM à l'EC2 
resource "aws_iam_instance_profile" "ec2_wordpress_profile" {
  name = "EC2WordPressProfile"
  role = aws_iam_role.ec2_wordpress_role.name

  lifecycle {
    ignore_changes = [name]
  }
}


// 🔹 Outputs
//////////////////////////////
output "instance_id" {
  description = "ID de l'instance EC2 WordPress"
  value       = aws_instance.wordpress.id
}

output "instance_public_ip" {
  description = "Adresse IP publique de l'instance EC2"
  value       = aws_instance.wordpress.public_ip
}
