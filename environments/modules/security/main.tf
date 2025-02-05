// environments/modules/security/main.tf

resource "aws_security_group" "wordpress" {
  name_prefix = "${var.project_name}-wp-${var.environment}"
  description = "Security group for WordPress instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-wp-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

output "wordpress_sg_id" {
  description = "ID of WordPress security group"
  value       = aws_security_group.wordpress.id
}
