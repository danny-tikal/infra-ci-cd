output "mongodb_endpoint" {
  description = "mongodb endpoint."
  value       = module.mongodb.mongodb_endpoint
}

output "mongodb_reader_endpoint" {
  description = "mongodb endpoint."
  value       = module.mongodb.mongodb_reader_endpoint
}