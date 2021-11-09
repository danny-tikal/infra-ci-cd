output "rabbitmq_endpoint" {
     value = aws_mq_broker.mq_broker.instances.0.console_url
}

output "rabbitmq_amqps_endpoint" {
     value = aws_mq_broker.mq_broker.instances.0.endpoints.0
}