

variable "env_profile" {}
variable "region" {}

# SECURITY
variable "subnet_ids" {}

# INFRA
variable "vpc_id" { default = "" }
variable "security_groups" {
  default = ""
}

# pods variables
variable "github_webhook_secret" {}
variable "redis_endpoint" {}
