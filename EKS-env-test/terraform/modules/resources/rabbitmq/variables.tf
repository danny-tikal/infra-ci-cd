# GENERAL

variable "env_profile" {
}
variable "owner" {
}

# SECURITY
variable "rabbitmq_subnet_ids" {
    type = set(string)
}
variable "security_groups" { default = ""}

# RABBITMQ

variable "engine_version" {
}

variable "broker_name" {
  
}

variable "deployment_mode" {
}
variable "engine_type" {
}
variable "host_instance_type" {
}
variable "general_logs" {
}

variable "publicly_accessible" {
}

variable "day_of_week" {
  
}

variable "time_of_day" {
  
}

variable "time_zone" {
  
}

variable "admin_username" {
  
}

variable "admin_password" {
  
}
