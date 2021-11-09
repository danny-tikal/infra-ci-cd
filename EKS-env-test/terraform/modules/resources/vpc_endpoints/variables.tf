# global
variable "env_profile" {
}

variable "region" {
}

variable "subnet_ids" {
}

variable "vpc_id" {
}

variable "owner" {
}
variable "component" {default = "endpoint"}

# endpoints
variable "service_endpoints" {
    default = []
}

variable "gateway_endpoints" {
    default = []
}

variable "security_group_ids" {
    
  }

# NETWORK

variable "route_tables" {
  default = []
}


