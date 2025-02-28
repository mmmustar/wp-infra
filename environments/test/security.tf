# Groupe de securite pour l'instance WordPress EC2
resource "aws_security_group" "wordpress" {
  name        = "${var.project_name}-ec2-sg-${var.environment}"
  description = "Groupe de securite pour la base de donneeRDS"
  vpc_id      = aws_vpc.main.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # Tout le trafic sortant
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tout le trafic sortant"
  }

  tags = {
    Name        = "${var.project_name}-ec2-sg-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Groupe de securite pour RDS
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg-${var.environment}"
  description = "Groupe_de_securite_pour_la_base_de_donneeRDS"
  vpc_id      = aws_vpc.main.id

  # MySQL/MariaDB
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress.id]
    description     = "MySQL depuis EC2"
  }

  # Tout le trafic sortant
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
