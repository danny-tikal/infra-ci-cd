# ECC
variable "env_profile" {}
variable "vpc_id" {}
variable "subnet_ids" {
    type = set(string)
}
variable "redis_engine_version" {}
variable "redis_sec_group_rules_list" {
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
variable "node_type" {}
variable "parameter_group_name" {}
variable "maintenance_window" {}
variable "snapshot_window" {}
variable "snapshot_retention_limit" {}
variable "automatic_failover_enabled" {}
variable "transit_encryption_enabled" {}
variable "at_rest_encryption_enabled" {}
variable "number_cache_clusters" {}
variable "multi_az_enabled" {}