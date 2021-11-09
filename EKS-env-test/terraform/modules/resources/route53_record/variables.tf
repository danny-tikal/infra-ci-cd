# Route53

variable "cname" {}
variable "zone_id" {}
variable "record" {}
variable "ttl" {
  default = 300
}
variable "type" {
  default = "CNAME"
}

