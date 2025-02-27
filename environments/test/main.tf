module "network" {
  source             = "../modules/network"
  environment        = var.environment
  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "database" {
  source                  = "../modules/database"
  environment             = var.environment
  project_name            = var.project_name
  subnet_ids              = module.network.private_subnet_ids
  security_group_id       = module.network.db_sg_id
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  db_allocated_storage    = var.db_allocated_storage
  db_instance_class       = var.db_instance_class
  db_storage_type         = var.db_storage_type
  db_engine_version       = var.db_engine_version
  db_parameter_group_name = var.db_parameter_group_name
  db_skip_final_snapshot  = var.db_skip_final_snapshot

  depends_on = [module.network]
}

module "compute" {
  source             = "../modules/compute"
  environment        = var.environment
  project_name       = var.project_name
  subnet_id          = module.network.public_subnet_ids[0]
  security_group_id  = module.network.wordpress_sg_id
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  key_name           = var.key_name
  root_volume_size   = var.root_volume_size
  eip_id             = var.eip_id != "" ? var.eip_id : module.network.eip_id
  db_name            = module.database.db_instance_name
  db_username        = module.database.db_instance_username
  db_password        = var.db_password
  db_endpoint        = module.database.db_instance_endpoint

  depends_on = [module.database]
}
