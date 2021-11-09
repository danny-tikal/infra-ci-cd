resource "aws_mq_broker" "mq_broker" {
  broker_name = var.broker_name

  # configuration {
  #   id       = aws_mq_configuration.test.id
  #   revision = aws_mq_configuration.test.latest_revision
  # }

  subnet_ids =        var.rabbitmq_subnet_ids
  engine_type         = var.engine_type
  engine_version      = var.engine_version
  host_instance_type  = var.host_instance_type
  security_groups     = var.security_groups
  deployment_mode     = var.deployment_mode
  
  # logs {
  #   audit             = false
  #   general           = false
  # }
  maintenance_window_start_time {
      day_of_week         = var.day_of_week
      time_of_day         = var.time_of_day
      time_zone           = var.time_zone
  }

  publicly_accessible = var.publicly_accessible

  user {
    username = var.admin_username
    password = var.admin_password
  }

  tags = {
    Name        = "${var.env_profile}-rabbitmq"
    Environment = var.env_profile
    Managed_by  = "Terraform"
    Owner       = var.owner
  }

}