  # cluster
  variable "env_profile" {
    
  }

  variable "owner" {
  }
  variable "engine" {
    
  }

  variable "availability_zones" {
    type = set(string)
  }

  variable "master_username" {
    
  }

  variable "master_password" {
    
  }

  variable "backup_retention_period" {
    
  }

  variable "preferred_backup_window" {
    
  }

  variable "preferred_maintenance_window" {
    
  }

  variable "allow_major_version_upgrade" {
    
  }

  variable "rds_engine_version" {
    
  }

  variable "storage_encrypted" {

}

  variable "deletion_protection" {
    
  }

  variable "enabled_cloudwatch_logs_exports" {
    type = list(string)
  }

  variable "skip_final_snapshot" {
    
  }

  variable "rds_vpc_security_group_ids" {
    
  }




# db subnet group

  variable "subnet_ids" {
    
  }

# cluster instance

  variable "replicas_count" {
    
  }

  variable "instance_class" {
    
  }
  
  variable "performance_insights_enabled" {
    
  }

  variable "database_name" {
    
  }


  variable "db_config_params" {
  description = "A config map with params for db. Is currently used with role creating and permission assignment."
  type        = any
  default     = []
}