resource "aws_vpc_peering_connection" "ec2_to_rds" {
  vpc_id      = var.ec2_vpc_id
  peer_vpc_id = var.rds_vpc_id
  auto_accept = false

  tags = {
    Name = "${var.project_name}-ec2-to-rds-peering-${var.environment}"
  }
}

resource "aws_route" "ec2_to_rds_route" {
  route_table_id         = var.route_table_id
  destination_cidr_block = var.rds_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.ec2_to_rds.id
}


resource "aws_route" "rds_to_ec2_route" {
  route_table_id         = var.rds_route_table_id
  destination_cidr_block = var.ec2_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.ec2_to_rds.id
}

resource "aws_security_group_rule" "allow_mysql_peering" {
  type        = "ingress"
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  security_group_id = var.rds_security_group_id
  cidr_blocks = [var.ec2_cidr_block]
}
