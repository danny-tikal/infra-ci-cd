resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name        = "${var.env_profile}-${var.instance_name}-subnet-group"
  subnet_ids  = var.instance_sn
  description = var.redis_subnet_description
}
