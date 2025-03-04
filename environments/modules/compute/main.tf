# environments/modules/compute/main.tf

# Recherche de l'AMI Ubuntu la plus récente
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

# Création de l'instance EC2 pour WordPress
resource "aws_instance" "wordpress" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name
  iam_instance_profile   = var.instance_profile

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  user_data = <<-EOF
#!/bin/bash
# Installation des dépendances de base
apt update -y
apt install -y apt-transport-https ca-certificates curl software-properties-common
# Ajout du référentiel Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update -y
apt install -y docker-ce
# Ajout de l'utilisateur ubuntu au groupe docker
usermod -aG docker ubuntu
# Installation de K3s
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

# Modification des permissions pour que l'utilisateur ubuntu puisse utiliser kubectl
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube
chmod 600 /home/ubuntu/.kube/config

# Installation de Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh

# Affecte les permissions correctes à l'utilisateur ubuntu pour Helm
mkdir -p /home/ubuntu/.config/helm
chown -R ubuntu:ubuntu /home/ubuntu/.config
chown -R ubuntu:ubuntu /home/ubuntu/.cache 2>/dev/null || true
EOF

  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }

  volume_tags = {
    Name        = "${var.project_name}-${var.environment}-root"
    Environment = var.environment
    Project     = var.project_name
  }
  
  # Empêcher la destruction accidentelle de l'instance
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [ami, user_data, tags]  # Permet de mettre à jour l'AMI sans détruire l'instance
  }
}

# Association de l'EIP à l'instance EC2 - toujours utiliser l'EIP existante
resource "aws_eip_association" "wordpress" {
  instance_id   = aws_instance.wordpress.id
  allocation_id = var.eip_allocation_id
  
  # Ne pas recréer l'association si l'instance change
  lifecycle {
    ignore_changes = [instance_id]
  }
}

# Volume supplémentaire pour le stockage des données
resource "aws_ebs_volume" "wordpress_data" {
  availability_zone = aws_instance.wordpress.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-data"
    Environment = var.environment
    Project     = var.project_name
  }
  
  # Empêcher la destruction accidentelle du volume de données
#  lifecycle {
#    prevent_destroy = true
#  }
}

# Attachement du volume de données
resource "aws_volume_attachment" "wordpress_data_att" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.wordpress_data.id
  instance_id = aws_instance.wordpress.id

  # Prévient la destruction du volume lors du détachement
  skip_destroy = true
}
