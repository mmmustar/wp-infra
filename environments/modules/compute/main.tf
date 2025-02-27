# environments/modules/compute/main.tf

# Sélection de l'AMI Ubuntu 20.04 LTS
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

# Création de l'instance EC2 WordPress
resource "aws_instance" "wordpress" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name
  
  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }
  
  tags = {
    Name        = "${var.project_name}-instance-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
  
  # Script d'initialisation pour installer WordPress
  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx mysql-client php-fpm php-mysql php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip

    # Installation de WordPress
    wget https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz -C /var/www/
    cp -r /var/www/wordpress/* /var/www/html/
    chown -R www-data:www-data /var/www/html/
    
    # Configuration de wp-config.php
    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
    sed -i "s/database_name_here/${var.db_name}/" /var/www/html/wp-config.php
    sed -i "s/username_here/${var.db_username}/" /var/www/html/wp-config.php
    sed -i "s/password_here/${var.db_password}/" /var/www/html/wp-config.php
    sed -i "s/localhost/${var.db_endpoint}/" /var/www/html/wp-config.php
    
    # Redémarrer Nginx
    systemctl restart nginx
  EOF
}

# Association de l'Elastic IP à l'instance EC2
resource "aws_eip_association" "wordpress" {
  instance_id   = aws_instance.wordpress.id
  allocation_id = var.eip_id
}