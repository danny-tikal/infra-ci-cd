
# GENERAL

variable "env_profile" {
}
# INFRA
variable "vpc_id" {}

# MONGODB

# cluster
variable "db_subnet_group_name" {}
variable "subnet_ids" {
    type = set(string)
}
variable "engine" {}
variable "availability_zones" {
  type = set(string)
}
variable "master_username" { default = "" }
variable "master_password" { default = "" }
variable "backup_retention_period" {}
variable "preferred_backup_window" {}
variable "preferred_maintenance_window" {}
variable "docdb_engine_version" {}
variable "storage_encrypted" {}
variable "deletion_protection" {}
variable "enabled_cloudwatch_logs_exports" {
  type = list(string)
}
variable "skip_final_snapshot" {}
variable "mongodb_vpc_security_group_ids" { default = "" }
variable "instance_class" {}

# SECURITY GROUP RULES
variable "mongodb_sec_group_rules_list" {
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



variable "rabbitmq_celery_broker_url" {
  
}

variable "mongodb_creds"{

}
variable "eds_rds_creds"{

}
variable "authorization_service_creds"{

}

variable "relic_license_key"{

}