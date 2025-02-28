# environments/modules/elastic_ip/main.tf

# Création de l'Elastic IP avec lifecycle pour éviter la destruction
resource "aws_eip" "wordpress" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-eip-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }

  # Empêcher la destruction de l'EIP pour maintenir l'association avec Cloudflare
  lifecycle {
    prevent_destroy = true
    ignore_changes = [tags]
  }
}