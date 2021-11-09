variable "vpc_id" {}
variable "env_profile" {}
variable "accepted_cidrs" {
  description = "accepted cidrs"
  type        = list(string)
}
variable "subnet_ids" {
  type = list(string)
}
variable "region" {}
variable "jenkins_master_ip" {}
variable "master_jenkins_sg_name_tag" {
  
}