# environments/modules/security/main.tf

resource "aws_security_group" "wordpress" {
  name_prefix = "${var.project_name}-wp-${var.environment}"
  description = "Security group for WordPress instance"
  vpc_id      = var.vpc_id

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

  # HTTP NodePort for Ingress
  ingress {
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22", "104.16.0.0/13"]
    description = "Allow Cloudflare HTTP - Ingress"
  }

  # HTTPS NodePort for Ingress
  ingress {
    from_port   = 30443
    to_port     = 30443
    protocol    = "tcp"
    cidr_blocks = ["173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22", "104.16.0.0/13"]
    description = "Allow Cloudflare HTTPS - Ingress"
  }

  # Metrics Server
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Metrics Server"
  }

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH"
  }

  # All outbound traffic
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