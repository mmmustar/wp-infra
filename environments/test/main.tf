module "network" {
  source = "../modules/network"
  
  environment = var.environment
  project_name = var.project_name
  vpc_cidr = "172.16.0.0/16"
  public_subnet_cidrs = ["172.16.1.0/24", "172.16.2.0/24"]
}
resource "aws_instance" "wordpress_test" {
  depends_on = [module.network]
  
  ami           = "ami-0d92749d46e71c34c"
  instance_type = "t2.micro"
  subnet_id     = module.network.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.wordpress_test.id]
  key_name      = "test-aws-key-pair-new"

  root_block_device {
    volume_size = 8
  }

  tags = {
    Name        = "WP-Instance-Test"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "wordpress_test" {
  depends_on = [module.network]
  
  name_prefix = "WP-SecurityGroup-Test-"
  description = "Security group for WordPress test instance"
  vpc_id      = module.network.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/16"]  # CIDR du VPC RDS
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "WP-SG-Test"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Data sources
data "aws_security_group" "rds" {
  id = "sg-00efe258e85b22a30"
}

data "aws_db_instance" "wordpress" {
  db_instance_identifier = "wordpress-db"
}

# Utiliser directement le VPC ID
variable "rds_vpc_id" {
  description = "VPC ID where RDS is located"
  type        = string
  default     = "vpc-0385cddb5bd815883"  # ID du VPC où se trouve le RDS
}

data "aws_vpc" "rds_vpc" {
  id = var.rds_vpc_id
}

# Créer le peering
resource "aws_vpc_peering_connection" "wordpress" {
  peer_vpc_id = var.rds_vpc_id
  vpc_id      = module.network.vpc_id
  auto_accept = true
  
  tags = {
    Name = "peering-wp-rds"
  }
}

# Ajouter la route vers le VPC RDS
resource "aws_route" "to_rds" {
  route_table_id            = module.network.route_table_id
  destination_cidr_block    = data.aws_vpc.rds_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.wordpress.id
}

resource "aws_route" "from_rds" {
  route_table_id         = data.aws_vpc.rds_vpc.main_route_table_id
  destination_cidr_block = "172.16.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.wordpress.id
}

# Outputs
output "rds_endpoint" {
  value = data.aws_db_instance.wordpress.endpoint
}

output "instance_public_ip" {
  value = aws_instance.wordpress_test.public_ip
}