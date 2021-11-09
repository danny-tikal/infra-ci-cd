resource "aws_elasticache_replication_group" "elasticache_cluster" {
  replication_group_id              = "${var.env_profile}-${var.instance_name}"
  replication_group_description     = var.description
  engine                            = "redis"
  engine_version                    = var.engine_version
  node_type                         = var.node_type
  number_cache_clusters             = var.number_cache_clusters
  parameter_group_name              = var.parameter_group_name
  port                              = 6379

  subnet_group_name                 = var.subnet_group_name
  security_group_ids                = var.security_group
  maintenance_window                = var.maintenance_window
  snapshot_window                   = var.snapshot_window
  snapshot_retention_limit          = var.snapshot_retention_limit
  automatic_failover_enabled        = var.automatic_failover_enabled

  transit_encryption_enabled        = var.transit_encryption_enabled
  at_rest_encryption_enabled        = var.at_rest_encryption_enabled
  multi_az_enabled                  = var.multi_az_enabled


  tags = {
    Name        = "${var.env_profile}-${var.instance_name}"
    Environment = var.env_profile
    Managed_by  = "Terraform"
    Owner       = var.owner
  }
}