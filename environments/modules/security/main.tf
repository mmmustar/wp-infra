resource "aws_security_group" "wordpress" {
  name_prefix = "${var.project_name}-wp-${var.environment}"
  description = "Security group for WordPress instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22", "104.16.0.0/13"]
    description = "Allow Cloudflare HTTP - Traefik"
  }

  ingress {
    from_port   = 30081
    to_port     = 30081
    protocol    = "tcp"
    cidr_blocks = ["173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22", "104.16.0.0/13"]
    description = "Allow Cloudflare HTTP - WordPress"
  }

  ingress {
    from_port   = 30443
    to_port     = 30443
    protocol    = "tcp"
    cidr_blocks = ["173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22", "104.16.0.0/13"]
    description = "Allow Cloudflare HTTPS"
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