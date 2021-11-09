output "redis_endpoint" {
  description = "redis endpoint."
  value       = "redis://${module.aws_elasticache_cluster.primary_endpoint_address}:6379"
}