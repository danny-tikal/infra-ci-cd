
# =======================================================================
# GENERAL
output "owner" {
  value = "devops"
}

# =======================================================================

output "aws_region" { value = "eu-west-1" }
output "zone_id" { value = "Z05489583DDG235A61QK2" } # explorium.ninja

output "default_vpc_id" { value = "vpc-e37c2284" }
output "dev_vpc_id" { value = "vpc-0106be38634e0e1dc" }
output "infra_vpc_id" { value = "vpc-077ade63d25186978" }
output "prod_vpc_id" { value = "vpc-06a7327c9b47a441b" }

output "default_vpc_cidr_block" { value = "172.31.0.0/16" }
output "dev_vpc_cidr_block" { value = "10.141.0.0/16" }
output "infra_vpc_cidr_block" { value = "192.168.0.0/16" }
output "prod_vpc_cidr_block" { value = "10.142.0.0/16" }

# DEFAULT
output "default_subnetid_a" { value = "subnet-5c733b3b" }
output "default_subnetid_b" { value = "subnet-847220cd" }
output "default_subnetid_c" { value = "subnet-7ed94d25" }

# DEV
output "dev_subnetid_a" { value = "subnet-07e1a128948d346e7" }
output "dev_subnetid_b" { value = "subnet-0a12ea5a627526065" }
output "dev_subnetid_c" { value = "subnet-06661e5854674e689" }

# INFRA
output "infra_subnetid_a" { value = "subnet-04af8f9b7761babee" }
output "infra_subnetid_b" { value = "subnet-0f88206b5d1999671" }
output "infra_subnetid_c" { value = "subnet-02b29961d6884c705" }

# PROD
output "prod_subnetid_a" { value = "subnet-0c9630b009399e36a" }
output "prod_subnetid_b" { value = "subnet-04bf0293f84f9d45a" }
output "prod_subnetid_c" { value = "subnet-05f980933b5666abe" }

# ========================
data "aws_caller_identity" "current" {}


output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}

output "caller_user" {
  value = data.aws_caller_identity.current.user_id
}