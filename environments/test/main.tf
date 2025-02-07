// 🔹 Utilisation du rôle IAM existant
data "aws_iam_role" "existing_ec2_wordpress_role" {
  name = "EC2-WordPress-Access"
}

// 🔹 Utilisation de la politique IAM existante
data "aws_iam_policy" "existing_secrets_manager_read" {
  arn = "arn:aws:iam::730335289383:policy/EC2SecretsManagerReadOnly"
}

// 🔹 Création du profil IAM pour l'EC2 (utilisant le rôle existant)
resource "aws_iam_instance_profile" "ec2_wordpress_profile" {
  name = "EC2WordPressProfile"
  role = data.aws_iam_role.existing_ec2_wordpress_role.name
}

// 🔹 Attachement de la politique IAM existante au rôle EC2
resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = data.aws_iam_role.existing_ec2_wordpress_role.name
  policy_arn = data.aws_iam_policy.existing_secrets_manager_read.arn
}

// 🔹 Création de l'instance EC2 WordPress
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

// 🔹 Outputs pour récupérer les infos de l'instance EC2
output "instance_id" {
  description = "ID de l'instance EC2"
  value       = aws_instance.wordpress.id
}

output "instance_public_ip" {
  description = "Adresse IP publique de l'EC2"
  value       = aws_instance.wordpress.public_ip
}
#cool