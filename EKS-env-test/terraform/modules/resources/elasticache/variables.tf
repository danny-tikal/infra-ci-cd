# GENERAL
variable "instance_name" {
}
variable "env_profile" {
}
variable "owner" {
}

# SECURITY
variable "subnet_group_name" {
}
variable "security_group" {
  type = list(string)
}

# ECC
variable "description" {
}
variable "engine_version" {
}
variable "node_type" {
}
variable "parameter_group_name" {
}
variable "number_cache_clusters" {

}
variable "automatic_failover_enabled" {
}

variable "transit_encryption_enabled" {
}
variable "at_rest_encryption_enabled" {
}

variable "multi_az_enabled" {}

variable "maintenance_window" {
}
variable "snapshot_window" {
}
variable "snapshot_retention_limit" {
}



