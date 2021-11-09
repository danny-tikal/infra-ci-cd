output "rds_endpoint" {
  description = "rds endpoint."
  value       = "postgresql://${local.rds_creds.username}:${local.rds_creds.password}@${module.rds-postgress.endpoint}:5432/${var.database_name}"
  sensitive = true
}

output "rds_url" {
  value = module.rds-postgress.endpoint
}