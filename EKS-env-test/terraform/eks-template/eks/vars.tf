variable "vpc_id" {
  description = "the vpc ID"
  type        = string
}
variable "private_subnets" {
  description = "The private subnets"
  type        = list(string)
}
variable "env_profile" {
  description = "The name of the environment"
  type        = string
}

variable "spot-min_size" {
  description = "spot-min_size"
  type        = number
}
variable "spot-max_size" {
  description = "spot-max_size"
  type        = number
}
variable "demand-min_size" {
  description = "demand-min_size"
  type        = number
}
variable "demand-max_size" {
  description = "demand-max_size"
  type        = number
}


variable "accepted_cidrs" {
  description = "accepted cidrs"
  type        = list(string)
}
variable "spot_instance_types" {
  description = "spot_instance_types"
  type = list(string)
  default = ["m5a.4xlarge", "m5ad.4xlarge", "m5.4xlarge", "m5d.4xlarge", "m5n.4xlarge", "m5dn.4xlarge", "m4.4xlarge"]
}
variable "ondemand_instance_types" {
  description = "ondemand_instance_types"
  type = string
  default = "m4.4xlarge"
}

variable "aws_account" {
  
}

variable "filebeat_creds" {
  
}