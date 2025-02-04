# environments/modules/compute/main.tf
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "wordpress" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnet.rds_subnet.id
  vpc_security_group_ids = [aws_security_group.wordpress.id]
  key_name      = var.key_name


  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.project_name}-instance-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_eip" "wordpress" {
  count    = var.environment == "test" ? 1 : 0
  instance = aws_instance.wordpress.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-eip-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}
data "aws_vpc" "rds_vpc" {
  id = "vpc-0385cddb5bd815883"
}

data "aws_subnet" "rds_subnet" {
  vpc_id = data.aws_vpc.rds_vpc.id
}
