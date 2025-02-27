# environments/modules/network/eip.tf

resource "aws_eip" "wordpress" {
  domain = "vpc"
  
  tags = {
    Name        = "${var.project_name}-eip-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}