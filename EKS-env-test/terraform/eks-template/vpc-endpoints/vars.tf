# global
variable "env_profile" { 
}

variable "region" {
}

variable "subnet_ids" {
    type = set(string)
}

variable "vpc_id" {
}

variable "owner" {
}
variable "component" {default = "endpoint"}

# endpoints
variable "service_endpoints" {
    type = list(string)
}

variable "gateway_endpoints" {
    type = list(string)
}
 
variable "security_group_ids" {
    default = []
  }

# NETWORK

variable "route_tables" {
  type = set(string)
}


# VPC ENDPOINTS

# SECURITY GROUP
# Endpoints SG Rules



variable "ep_sec_group_rules_list" {
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
