# environments/modules/database/main.tf

# Groupe de sous-réseaux pour RDS
resource "aws_db_subnet_group" "wordpress" {
  name       = "${var.project_name}-${var.environment}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.project_name}-subnet-group-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Groupe de paramètres (optimisé pour WordPress)
resource "aws_db_parameter_group" "wordpress" {
  name   = "${var.project_name}-${var.environment}-mysql-params"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  # Optimisations de performances pour WordPress
  parameter {
    name  = "max_connections"
    value = var.environment == "prod" ? "150" : "50"
  }

  tags = {
    Name        = "${var.project_name}-mysql-params-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Instance RDS MySQL avec optimisations de coûts
resource "aws_db_instance" "wordpress" {
  identifier             = "${var.project_name}-rds-wp-${var.environment}"
  allocated_storage      = var.allocated_storage
  storage_type           = "gp3"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.instance_class
  db_name                = var.database_name
  username               = var.database_username
  password               = var.database_password
  parameter_group_name   = aws_db_parameter_group.wordpress.name
  db_subnet_group_name   = aws_db_subnet_group.wordpress.name
  vpc_security_group_ids = [var.security_group_id]
  
  # Optimisations de coûts
  skip_final_snapshot    = true
  multi_az               = var.environment == "prod" ? var.multi_az : false
  backup_retention_period = var.environment == "prod" ? 7 : 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Sun:04:30-Sun:05:30"
  
  # Options de performances
  performance_insights_enabled = var.environment == "prod"
  apply_immediately       = true

  lifecycle {
    # prevent_destroy = true
    # ignore_changes  = [engine_version, tags]
  }

  tags = {
    Name        = "${var.project_name}-mysql-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}
