# Set common variables for the region. This is automatically pulled in in the root terragrunt.hcl configuration to
# configure the remote state bucket and pass forward to the child modules as inputs.
locals {
  aws_region = "eu-west-1"
  customer_gw = "cgw-059a21f3fccad7975"
  destination_p81_cidr = "10.255.0.0/16"
  management_tgw_id    = "tgw-08ab8403141d4058a"
}
