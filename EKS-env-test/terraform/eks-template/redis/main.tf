# =================================================================================

module "subnet_group" {
  source                     = "../../modules/resources/elasticache/subnet_group"

  instance_name              = "redis-${var.env_profile}"
  env_profile                = var.env_profile
  instance_sn                = var.subnet_ids
  redis_subnet_description   = "${var.env_profile}-redis-subnet-group"

}
# =================================================================================

module "redis-sg" {
  source                     = "../../modules/resources/security_group"
  vpc_id                     = var.vpc_id
  instance_name              = "redis-${var.env_profile}"
  env_profile                = var.env_profile
  component                  = "redis"
  sg_description             = "Security group for Redis Brocker ${var.env_profile}"
  sec_group_rules_list       = var.redis_sec_group_rules_list
}
# =================================================================================

# =================================================================================

module "aws_elasticache_cluster" {
  source                     = "../../modules/resources/elasticache"

  instance_name              = "redis"
  env_profile                = var.env_profile
  owner                      = var.env_profile
  description                = "redis for eks-${var.env_profile}"

  subnet_group_name          = module.subnet_group.subnet_group_id
  security_group             = module.redis-sg.instance_sg

  engine_version             = var.redis_engine_version
  node_type                  = var.node_type
  parameter_group_name       = var.parameter_group_name
  number_cache_clusters      = var.number_cache_clusters
  maintenance_window         = var.maintenance_window
  snapshot_window            = var.snapshot_window

  automatic_failover_enabled = var.automatic_failover_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  multi_az_enabled           = var.multi_az_enabled
  snapshot_retention_limit   = var.snapshot_retention_limit

}