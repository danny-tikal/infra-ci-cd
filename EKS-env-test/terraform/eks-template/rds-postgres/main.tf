
# =================================================================================

module "rds-sg" {
  source                     = "../../modules/resources/security_group"
  vpc_id                     = var.vpc_id
  instance_name              = "rds-postgress-${var.env_profile}"
  env_profile                = var.env_profile
  component                  = "rds-postgress"
  sg_description             = "Security group for Rds Postgress ${var.env_profile}"
  sec_group_rules_list       = var.rds_sec_group_rules_list
}
# =================================================================================

data "aws_kms_secrets" "rds_creds" {
  secret {
    name    = "rds_creds"
    payload = file(var.rds_creds)
  }
}

locals {
  rds_creds             = yamldecode(data.aws_kms_secrets.rds_creds.plaintext["rds_creds"])
}

# =================================================================================

module "rds-postgress" {
  source                          = "../../modules/resources/rds"
  env_profile                     = var.env_profile
  owner                           = var.env_profile
  database_name                   = var.database_name
  engine                          = var.engine
  availability_zones              = var.availability_zones
  master_username                 = local.rds_creds.username
  master_password                 = local.rds_creds.password
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  allow_major_version_upgrade     = var.allow_major_version_upgrade
  rds_engine_version              = var.rds_engine_version
  storage_encrypted               = var.storage_encrypted
  deletion_protection             = var.deletion_protection
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  skip_final_snapshot             = var.skip_final_snapshot
  # db subnets groups
  subnet_ids                      = var.subnet_ids
  # cluster instance
  replicas_count                  = var.replicas_count
  performance_insights_enabled    = var.performance_insights_enabled
  instance_class                  = var.instance_class
  rds_vpc_security_group_ids      = module.rds-sg.instance_sg
  db_config_params                = var.db_config_params 
}

# =================================================================================
