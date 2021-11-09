
# RABBITMQ
# GENERAL
variable "broker_name" {

}

variable "env_profile" {
}

# SECURITY
variable "subnet_ids" {
  type = set(string)
}

# RABBITMQ

variable "engine_version" {
}

variable "deployment_mode" {
}
variable "engine_type" {
}
variable "host_instance_type" {
}
variable "general_logs" {
}

variable "day_of_week" {

}

variable "time_zone" {

}

variable "time_of_day" {

}
variable "publicly_accessible" {
}

variable "admin_username" { default = "" }

variable "admin_password" { default = "" }

# INFRA
variable "vpc_id" { default = "" }

variable "security_groups" {
  default = ""
}

# SECURITY GROUP RULES
variable "rabbitmq_sg_description" {}
variable "rabbitmq_sec_group_rules_list" {
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

variable "rabbitmq_creds" {
  
}
variable "rabbitmq_user_pass" {
  
}