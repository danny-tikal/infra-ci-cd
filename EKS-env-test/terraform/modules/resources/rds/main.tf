resource "aws_rds_cluster" "postgresql" {
  cluster_identifier              = "explorium-${var.env_profile}"
  engine                          = var.engine
  availability_zones              = var.availability_zones
  database_name                   = var.database_name
  master_username                 = var.master_username
  master_password                 = var.master_password
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  allow_major_version_upgrade     = var.allow_major_version_upgrade
  engine_version                  = var.rds_engine_version
  storage_encrypted               = var.storage_encrypted
  # deletion_protection             = var.deletion_protection
  deletion_protection             = false
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  db_subnet_group_name            = "${var.env_profile}-private-subnet-group"
  skip_final_snapshot             = var.skip_final_snapshot
  vpc_security_group_ids          = var.rds_vpc_security_group_ids
  depends_on                      = [aws_db_subnet_group.default]
  
  tags = {
    Name        = "explorium-${var.env_profile}"
    Environment = var.env_profile
    Managed_by  = "Terraform"
    Owner       = var.owner
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.env_profile}-private-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "explorium-${var.env_profile} DB subnet group"
    Environment = var.env_profile
    Managed_by  = "Terraform"
    Owner       = var.owner
  }
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count                        = var.replicas_count
  identifier                   = "explorium-${var.env_profile}-${count.index}"
  cluster_identifier           = aws_rds_cluster.postgresql.id
  instance_class               = var.instance_class
  engine                       = aws_rds_cluster.postgresql.engine
  engine_version               = aws_rds_cluster.postgresql.engine_version
  performance_insights_enabled = var.performance_insights_enabled
  preferred_maintenance_window = var.preferred_maintenance_window
  depends_on                   = [aws_rds_cluster.postgresql]

  tags = {
    Name        = "explorium-${var.env_profile}-writer"
    Environment = var.env_profile
    Managed_by  = "Terraform"
    Owner       = var.owner
  }
}

### Reader instance
resource "aws_rds_cluster_instance" "main_reader" {

  count = var.db_config_params.create_reader_instance ? 1 : 0


  identifier                    = "explorium-${var.env_profile}-reader"
  cluster_identifier           = aws_rds_cluster.postgresql.id
  instance_class               = var.instance_class
  engine                       = aws_rds_cluster.postgresql.engine
  engine_version               = aws_rds_cluster.postgresql.engine_version
  performance_insights_enabled = var.performance_insights_enabled
  preferred_maintenance_window = var.preferred_maintenance_window
  # hacky wacky to force reader instance creation  https://github.com/hashicorp/terraform-provider-aws/issues/11324
  depends_on    = [aws_rds_cluster_instance.cluster_instances]

  tags = {
    Name        = "explorium-${var.env_profile}-reader"
    Environment = var.env_profile
    Managed_by  = "Terraform"
    Owner       = var.owner
  }
}


provider "postgresql" {
  alias           = "admindb"
  host            = aws_rds_cluster.postgresql.endpoint
  port            = 5432
  database        = var.database_name
  username        = var.master_username
  password        = var.master_password
  sslmode         = "require"
  connect_timeout = 15
  superuser       = false
}

resource "postgresql_role" "ro_role" {

  # if create_ro_db_user = true create resouce
  count = var.db_config_params.create_ro_db_user ? 1 : 0

  provider    = postgresql.admindb
  name        = "${var.master_username}_ro"
  login       = true
  password    = lookup(var.db_config_params, "readonly_user_password", local.db_config_params["readonly_user_password"]) 
  depends_on  = [aws_rds_cluster.postgresql]
}


resource "postgresql_grant" "select_only_on_schema" {

  # if create_ro_db_user = true create resouce
  count = var.db_config_params.create_ro_db_user ? 1 : 0

  provider    = postgresql.admindb
  database    = var.database_name
  role        = "${var.master_username}_ro"
  schema      = lookup(var.db_config_params, "db_schema_name", local.db_config_params["db_schema_name"])
  object_type = "table"
  privileges  = ["SELECT"]
  depends_on  = [postgresql_role.ro_role]
}