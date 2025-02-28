# environments/modules/security/main.tf

# Groupe de sécurité pour les instances WordPress
resource "aws_security_group" "wordpress" {
  name_prefix = "${var.project_name}-wp-${var.environment}"
  description = "Groupe de sécurité pour les instances WordPress"
  vpc_id      = var.vpc_id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Accès HTTP"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Accès HTTPS"
  }

  # SSH (restreindre idéalement à certaines IPs)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_ips
    description = "Accès SSH"
  }

  # K3s API Server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "K3s API Server"
  }

  # K3s VXLAN (Flannel networking)
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "K3s VXLAN"
  }

  # K3s Kubelet
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "K3s Kubelet"
  }

  # Nodeport range for K3s
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "K3s NodePort Range"
  }

  # Pour Cloudflare, on peut spécifier leurs plages d'IP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cloudflare_ip_ranges
    description = "Cloudflare HTTP access"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cloudflare_ip_ranges
    description = "Cloudflare HTTPS access"
  }

  # Tout le trafic sortant est autorisé
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tout le trafic sortant"
  }

  tags = {
    Name        = "${var.project_name}-wp-sg-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Groupe de sécurité pour la base de données RDS
resource "aws_security_group" "database" {
  name_prefix = "${var.project_name}-db-${var.environment}"
  description = "Groupe de sécurité pour la base de données RDS"
  vpc_id      = var.vpc_id

  # MySQL
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress.id]
    description     = "Accès MySQL depuis WordPress"
  }

  # Tout le trafic sortant est autorisé
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tout le trafic sortant"
  }

  tags = {
    Name        = "${var.project_name}-db-sg-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Création du rôle IAM pour l'EC2
resource "aws_iam_role" "ec2_wordpress_role" {
  name = "${var.project_name}-${var.environment}-EC2WordPressRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  
  lifecycle {
    ignore_changes = [name]
  }
}

# Politique pour accéder à Secrets Manager
resource "aws_iam_policy" "secrets_manager_read" {
  name        = "${var.project_name}-${var.environment}-SecretsManagerReadOnly"
  description = "Autorisation pour lire les secrets de Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = "*"
    }]
  })
}

# Attachement de la politique au rôle
resource "aws_iam_role_policy_attachment" "secrets_attach" {
  role       = aws_iam_role.ec2_wordpress_role.name
  policy_arn = aws_iam_policy.secrets_manager_read.arn
}

# Création du profil d'instance
resource "aws_iam_instance_profile" "ec2_wordpress_profile" {
  name = "${var.project_name}-${var.environment}-EC2WordPressProfile"
  role = aws_iam_role.ec2_wordpress_role.name
}