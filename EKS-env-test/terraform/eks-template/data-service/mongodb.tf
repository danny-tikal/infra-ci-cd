
# =================================================================================

module "mongodb-sg" {
  source               = "../../modules/resources/security_group"
  vpc_id               = var.vpc_id
  instance_name        = "mongodb-${var.env_profile}"
  env_profile          = var.env_profile
  component            = "mongodb"
  sg_description       = "Security group for MongoDb ${var.env_profile}"
  sec_group_rules_list = var.mongodb_sec_group_rules_list
}
# =================================================================================

data "aws_kms_secrets" "mongodb_creds" {
  secret {
    name    = "mongodb_creds"
    payload = file(var.mongodb_creds)
  }
}

locals {
  mongodb_creds = yamldecode(data.aws_kms_secrets.mongodb_creds.plaintext["mongodb_creds"])
}

# =================================================================================

module "mongodb" {
  source                          = "../../modules/resources/mongodb"
  env_profile                     = var.env_profile
  owner                           = var.env_profile
  engine                          = var.engine
  availability_zones              = var.availability_zones
  master_username                 = local.mongodb_creds.username
  master_password                 = local.mongodb_creds.password
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  docdb_engine_version            = var.docdb_engine_version
  storage_encrypted               = var.storage_encrypted
  deletion_protection             = var.deletion_protection
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  skip_final_snapshot             = var.skip_final_snapshot
  subnet_ids                      = var.subnet_ids
  instance_class                  = var.instance_class
  mongodb_vpc_security_group_ids  = module.mongodb-sg.instance_sg
}

# =================================================================================
