# GENERAL
variable "instance_name" {}
variable "env_profile" {}

variable "redis_subnet_description" {
  description = "Subnet group description"
}
variable "instance_sn" {
  type = list
  description = "Subnet we going to attach to instance"
}




