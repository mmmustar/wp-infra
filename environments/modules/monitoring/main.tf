# Data source pour l'AMI Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Création d'un groupe de sécurité dédié pour l'instance de monitoring
resource "aws_security_group" "monitoring_sg" {
  name        = "${var.project_name}-monitoring-sg-${var.environment}"
  description = "Security Group dedie pour l instance de monitoring"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Acces pour le scraping des metriques (node_exporter)"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_ips
    description = "Acces SSH"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tout le trafic sortant"
  }

  tags = {
    Name        = "${var.project_name}-monitoring-sg-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Elastic IP pour l'instance de monitoring
resource "aws_eip" "monitoring" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-monitoring-eip-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags]
  }
}

# Instance EC2 pour le monitoring
resource "aws_instance" "monitoring" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]
  key_name               = var.key_name
  iam_instance_profile   = var.instance_profile

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }
  
  tags = {
    Name        = "${var.project_name}-monitoring-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
  
  volume_tags = {
    Name        = "${var.project_name}-monitoring-${var.environment}-root"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Association de l'EIP à l'instance de monitoring
resource "aws_eip_association" "monitoring" {
  instance_id   = aws_instance.monitoring.id
  allocation_id = aws_eip.monitoring.allocation_id
}

# Volume EBS supplémentaire pour les données de monitoring
resource "aws_ebs_volume" "monitoring_data" {
  availability_zone = aws_instance.monitoring.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true

  tags = {
    Name        = "${var.project_name}-monitoring-${var.environment}-data"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attachement du volume EBS
resource "aws_volume_attachment" "monitoring_data_att" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.monitoring_data.id
  instance_id = aws_instance.monitoring.id
  skip_destroy = true
}
