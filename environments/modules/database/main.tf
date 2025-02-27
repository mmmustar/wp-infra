# environments/modules/database/main.tf

# Groupe de sous-réseaux pour RDS
resource "aws_db_subnet_group" "wordpress" {
  name       = "${var.project_name}-db-subnet-group-${var.environment}"
  subnet_ids = var.subnet_ids
  
  tags = {
    Name        = "${var.project_name}-db-subnet-group-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Instance RDS MySQL
resource "aws_db_instance" "wordpress" {
  identifier             = "rds-wp-${var.environment}"
  allocated_storage      = var.db_allocated_storage
  storage_type           = var.db_storage_type
  engine                 = "mysql"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = var.db_parameter_group_name
  skip_final_snapshot    = var.db_skip_final_snapshot
  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.wordpress.name
  
  tags = {
    Name        = "${var.project_name}-db-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}