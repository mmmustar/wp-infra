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

# Instances RDS MySQL avec optimisations de coûts
resource "aws_db_instance" "wordpress" {
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
  backup_retention_period = var.environment == "prod" ? 7 : 1  # 7 jours en prod, 1 jour en test
  backup_window           = "03:00-04:00"  # Fenêtre de sauvegarde à 3h du matin UTC
  maintenance_window      = "Sun:04:30-Sun:05:30"  # Maintenance le dimanche matin
  
  # Options de performances
  performance_insights_enabled = var.environment == "prod"  # Désactivé en test pour réduire les coûts
  apply_immediately       = true

  # Empêcher la destruction accidentelle
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [
      engine_version,  # Permet les mises à jour mineures sans changer le plan Terraform
      tags
    ]
  }

  tags = {
    Name        = "${var.project_name}-mysql-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Secret pour stocker les identifiants de base de données
resource "aws_secretsmanager_secret" "database_credentials" {
  name        = "${var.project_name}/${var.environment}/database-credentials"
  description = "Identifiants de connexion pour la base de données WordPress"
  
  tags = {
    Name        = "${var.project_name}-db-credentials-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id = aws_secretsmanager_secret.database_credentials.id
  secret_string = jsonencode({
    username     = var.database_username
    password     = var.database_password
    host         = aws_db_instance.wordpress.address
    port         = aws_db_instance.wordpress.port
    database     = var.database_name
    url          = "mysql://${var.database_username}:${var.database_password}@${aws_db_instance.wordpress.address}:${aws_db_instance.wordpress.port}/${var.database_name}"
  })
}
