// Sélection de l'AMI Ubuntu 20.04 LTS
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  // Propriétaire Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

## 🔹 Rôle IAM pour l’EC2
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

## 🔹 Politique IAM pour AWS Secrets Manager (Lecture seule)
resource "aws_iam_policy" "secrets_manager_read" {
  name        = "EC2SecretsManagerReadOnly"
  description = "Accès en lecture seule aux secrets dans AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = "*"
    }]
  })
}

## 🔹 Attachement de la politique au rôle IAM
resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.ec2_wordpress_role.name
  policy_arn = aws_iam_policy.secrets_manager_read.arn
}

## 🔹 Création d’un profil IAM pour l’EC2
resource "aws_iam_instance_profile" "ec2_wordpress_profile" {
  name = "EC2WordPressProfile"
  role = aws_iam_role.ec2_wordpress_role.name
}

## 🔹 Création de l'instance EC2 WordPress
resource "aws_instance" "wordpress" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.security_group_id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  ## 🔗 Attacher le rôle IAM à l'instance
  iam_instance_profile = aws_iam_instance_profile.ec2_wordpress_profile.name

  tags = {
    Name        = "${var.project_name}-instance-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

## 🔹 Outputs
output "instance_id" {
  description = "ID de l'instance EC2"
  value       = aws_instance.wordpress.id
}

output "instance_public_ip" {
  description = "Adresse IP publique de l'EC2"
  value       = aws_instance.wordpress.public_ip
}

output "instance_private_ip" {
  description = "Adresse IP privée de l'EC2"
  value       = aws_instance.wordpress.private_ip
}
