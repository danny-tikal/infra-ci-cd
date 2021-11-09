output "rabbitmq_endpoint" {
  description = "rabbitmq endpoint."
  value       = module.rabbitmq.rabbitmq_endpoint
}
output "rabbitmq_amqps_endpoint" {
  description = "rabbitmq amqps endpoint."
  value       = module.rabbitmq.rabbitmq_amqps_endpoint
}

output "rabbitmq_celery_broker_url" {
  description = "rabbitmq_celery_broker_url"
  value       = local.rabbitmq_broker_url
  sensitive = true
}

output "rabbitmq_flower_broker_url" {
  description = "rabbitmq_flower_broker_url"
  value       = local.flower_broker_url
  sensitive = true
}

output "rabbit_password"{
  value = local.rabbitmq_user_pass.password
  sensitive = true
}

output "rabbit_username"{
  value = local.rabbitmq_creds.username
  sensitive = true
}
output "rabbit_admin_password"{
  value = local.rabbitmq_creds.password
  sensitive = true
}