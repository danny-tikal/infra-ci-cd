resource "aws_security_group" "instance_sg" {
  name        = "${var.env_profile}-${var.component}-${var.instance_name}-sg"
  description = var.sg_description
  vpc_id      = var.vpc_id

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    description     = "Egress rule"
  }

  tags = {
    Name        = "${var.env_profile}-${var.component}-${var.instance_name}-sg"
    Environment = var.env_profile
    Managed_by  = "Terraform"
    Owner       = "DevOps"
    Datetime    = formatdate("DD MMMM YYYY hh:mm", timestamp())
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes = [tags["Datetime"]]
  }
}
