
# =================================================================================

module "sg" {
  source                     = "../../modules/resources/security_group"
  vpc_id                     = var.vpc_id
  instance_name              = "rabbitmq-${var.env_profile}"
  env_profile                = var.env_profile
  component                  = "rabbitmq"
  sg_description             = var.rabbitmq_sg_description
  sec_group_rules_list       = var.rabbitmq_sec_group_rules_list
}
# =================================================================================

# =================================================================================
data "aws_kms_secrets" "rabbitmq_creds" {
  secret {
    name    = "rabbitmq_creds"
    payload = file(var.rabbitmq_creds)
  }
}

locals {
  rabbitmq_creds = yamldecode(data.aws_kms_secrets.rabbitmq_creds.plaintext["rabbitmq_creds"])
}

data "aws_kms_secrets" "rabbitmq_user_pass" {
  secret {
    name    = "rabbitmq_user_pass"
    payload = file(var.rabbitmq_user_pass)
  }
}

locals {
  rabbitmq_user_pass = yamldecode(data.aws_kms_secrets.rabbitmq_user_pass.plaintext["rabbitmq_user_pass"])
  rabbitmq_host_port  = split( "/" , module.rabbitmq.rabbitmq_amqps_endpoint )[2]
  rabbitmq_broker_url = "amqps://${var.env_profile}-${var.env_profile}:${local.rabbitmq_user_pass.password}@${local.rabbitmq_host_port}/${var.env_profile}-${var.env_profile}"
  flower_broker_url   = "amqp://${var.env_profile}-${var.env_profile}:${local.rabbitmq_user_pass.password}@${local.rabbitmq_host_port}/${var.env_profile}-${var.env_profile}?ssl=true"
}


module "rabbitmq" {
  source                      = "../../modules/resources/rabbitmq"

  env_profile                 = var.env_profile
  owner                       = var.env_profile
  security_groups              = module.sg.instance_sg
  rabbitmq_subnet_ids         = var.subnet_ids

  broker_name                 = var.broker_name
  engine_version              = var.engine_version
  deployment_mode             = var.deployment_mode
  engine_type                 = var.engine_type
  host_instance_type          = var.host_instance_type
  general_logs                = var.general_logs
  day_of_week                 = var.day_of_week
  time_of_day                 = var.time_of_day
  time_zone                   = var.time_zone
  publicly_accessible         = var.publicly_accessible
  
  admin_username              = local.rabbitmq_creds.username
  admin_password              = local.rabbitmq_creds.password

}
# =================================================================================
