

variable "env_profile" {
}
variable "region" {
}

# SECURITY
variable "subnet_ids" {
}

# INFRA
variable "vpc_id" { default = "" }

variable "security_groups" {
  default = ""
}
variable "AUTH0_DOMAIN" {}

# pods variables
variable "app_database_name" {}
variable "CS_STAGE" {}
variable "EM_STAGE" {}
variable "RT_CELERY_RESULT_BACKEND" {}
variable "SHARED_VOLUME" {}
variable "MACHINE_TYPE" {}
variable "PROMETHEUS_USERNAME" {}
variable "PROMETHEUS_PASSWORD" {}
variable "github_webhook_secret" {}

variable "redis_endpoint" {

}

variable "rds_endpoint" {

}

variable "rabbitmq_celery_broker_url" {
}
variable "rabbitmq_flower_broker_url" {
}


variable "lily_creds" {

}
variable "aws_creds" {
  
}
variable "auth0_creds" {
  
}