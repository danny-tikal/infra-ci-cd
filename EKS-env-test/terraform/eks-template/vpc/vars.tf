variable "env_profile" {
  description = "The name of the environment"
  type        = string
}

variable "vpc_cidr" {
  description = "The vpc cidr"
  type        = string
}

variable "private_subnets" {
  description = "The private subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "The public subnets"
  type        = list(string)
}

variable "customer_gw" {
  description = "customer gw"
  type        = string
}

variable "destination_p81_cidr" {
  description = "destination p81 cidr"
  type        = string
}

variable "management_tgw_id" {
  description = "management tgw id"
  type        = string
}
