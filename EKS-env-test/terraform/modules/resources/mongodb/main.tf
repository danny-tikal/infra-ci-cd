resource "aws_docdb_cluster" "docdb" {
  cluster_identifier              = "explorium-${var.env_profile}-mongo"
  engine                          = var.engine
  availability_zones              = var.availability_zones
  master_username                 = var.master_username
  master_password                 = var.master_password
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  engine_version                  = var.docdb_engine_version
  storage_encrypted               = var.storage_encrypted
  deletion_protection             = false
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  db_subnet_group_name            = aws_docdb_subnet_group.default.name
  skip_final_snapshot             = var.skip_final_snapshot
  vpc_security_group_ids          = var.mongodb_vpc_security_group_ids
  depends_on                      = [aws_docdb_subnet_group.default, aws_docdb_cluster_parameter_group.docdb]
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.docdb.name
  
  tags = {
    Name        = "explorium-${var.env_profile}"
    Environment = var.env_profile
    Managed_by  = "Terraform"
    Owner       = var.owner
  }
}

resource "aws_docdb_subnet_group" "default" {
  name       = "${var.env_profile}-mongo-private-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "explorium-${var.env_profile} doc DB subnet group"
    Environment = var.env_profile
    Managed_by  = "Terraform"
    Owner       = var.owner
  }
}
resource "aws_docdb_cluster_parameter_group" "docdb" {
  name   = "${var.env_profile}-docdb-tls-disabled-4-0"
  family = "docdb4.0"
  description = "docdb cluster parameter group"

  parameter {
    name  = "tls"
    value = "disabled"
  }
  tags = {
    Name = "explorium-${var.env_profile} doc DB parameter group"
    Environment = var.env_profile
    Managed_by  = "Terraform"
    Owner       = var.owner
  }
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  # count                        = var.replicas_count
  # identifier                   = "explorium-${var.env_profile}-${count.index}"
  identifier                   = "explorium-${var.env_profile}-mongo"
  cluster_identifier           = aws_docdb_cluster.docdb.id
  instance_class               = var.instance_class
  engine                       = aws_docdb_cluster.docdb.engine
  preferred_maintenance_window = var.preferred_maintenance_window
  depends_on                   = [aws_docdb_cluster.docdb]

  tags = {
    Name        = "explorium-${var.env_profile}-writer"
    Environment = var.env_profile
    Managed_by  = "Terraform"
    Owner       = var.owner
  }
}