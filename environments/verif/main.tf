# environments/test/main.tf

# Configuration du provider AWS
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Module Network - Étape 1
module "network" {
  source               = "../modules/network"
  environment          = var.environment
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# Module Security - Transversal
module "security" {
  source       = "../modules/security"
  environment  = var.environment
  project_name = var.project_name
  vpc_id       = module.network.vpc_id
}

# Module Elastic IP - Étape 2
# Remarque: Ce module ne sera appelé que lors de la création initiale
# Pour les déploiements ultérieurs, nous utiliserons l'EIP existante
module "elastic_ip" {
  source       = "../modules/elastic_ip"
  environment  = var.environment
  project_name = var.project_name
  
  # Dépendance explicite
  depends_on = [module.network]
}

# Module Database - Étape 3f
module "database" {
  source                 = "../modules/database"
  environment            = var.environment
  project_name           = var.project_name
  subnet_ids             = module.network.private_subnet_ids
  security_group_id      = module.security.database_sg_id
  allocated_storage      = var.db_allocated_storage
  instance_class         = var.db_instance_class
  database_name          = var.db_name
  database_username      = var.db_username
  database_password      = var.db_password
  multi_az               = var.db_multi_az
  
  # Dépendance explicite
  depends_on = [module.network, module.security]
}

# Module Compute - Étape 4
module "compute" {
  source            = "../modules/compute"
  environment       = var.environment
  project_name      = var.project_name
  vpc_id            = module.network.vpc_id
  subnet_id         = module.network.public_subnet_ids[0]
  security_group_id = module.security.wordpress_sg_id
  instance_type     = var.instance_type
  ami_id            = var.ami_id
  key_name          = var.key_name
  instance_profile  = module.security.ec2_instance_profile_name
  root_volume_size  = var.root_volume_size
  data_volume_size  = var.data_volume_size
  
  # Utiliser l'EIP existante
  eip_allocation_id = var.eip_allocation_id
  
  # Dépendance explicite
  depends_on = [module.network, module.security, module.database]
}

module "monitoring" {
  source            = "../modules/monitoring"
  environment       = var.environment
  project_name      = var.project_name
  vpc_id            = module.network.vpc_id
  subnet_id         = module.network.public_subnet_ids[1]
  instance_type     = "t2.small"
  ami_id            = var.ami_id
  key_name          = var.key_name
  instance_profile  = module.security.ec2_instance_profile_name
  root_volume_size  = 20
  data_volume_size  = 30
  ssh_allowed_ips   = var.ssh_allowed_ips
}