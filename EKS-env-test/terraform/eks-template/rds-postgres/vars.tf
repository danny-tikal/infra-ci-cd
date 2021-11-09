
# INFRA
variable "vpc_id" { default = "" }
variable "env_profile" {}
variable "security_groups" {
  default = ""
}

# SECURITY GROUP RULES
variable "subnet_ids" {
  type = set(string)
}

# RDS-POSTGRESS
# cluster
variable "database_name" {}
variable "engine" {}
variable "availability_zones" {
  type = set(string)
}
variable "master_username" { default = "" }
variable "master_password" { default = "" }
variable "backup_retention_period" {}
variable "preferred_backup_window" {}
variable "preferred_maintenance_window" {}
variable "allow_major_version_upgrade" {}
variable "rds_engine_version" {}
variable "storage_encrypted" {}
variable "deletion_protection" {}
variable "enabled_cloudwatch_logs_exports" {
  type = list(string)
}
variable "skip_final_snapshot" {}
variable "rds_vpc_security_group_ids" { default = "" }
# cluster instance
variable "replicas_count" {}
variable "instance_class" {}
variable "performance_insights_enabled" {}
variable "rds_sec_group_rules_list" {
  description = "Rules list we want to add"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_block  = list(string)
    description = string
  }))
  default = []
}

variable "rds_creds" {

}

variable "db_config_params" {
  description = "A config map with params for db. Is currently used with role creating and permission assignment."
  type        = any
  default     = []
}