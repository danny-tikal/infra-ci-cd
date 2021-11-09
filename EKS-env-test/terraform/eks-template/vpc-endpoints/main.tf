
# provider "aws" {
#   region = var.region
# }

module "security_group" { 
  source                     = "../../modules/resources/security_group"
  count                      = length(var.service_endpoints)
  vpc_id                     = var.vpc_id
  instance_name              = replace("${var.service_endpoints[count.index]}-${var.env_profile}",".", "-")
  
  env_profile                = var.env_profile
  component                  = "vpc-endpoint"
  sg_description             = "Security group for vpce ${var.env_profile}-${var.service_endpoints[count.index]}"
  sec_group_rules_list       = var.ep_sec_group_rules_list
}

# ================================================================================= 

module "vpc_endpoints" {
  source                     = "../../modules/resources/vpc_endpoints"
  env_profile                = var.env_profile
  owner                      = var.owner
  service_endpoints          = var.service_endpoints
  gateway_endpoints          = var.gateway_endpoints
  route_tables               = var.route_tables
  region                     = var.region
  subnet_ids                 = var.subnet_ids
  vpc_id                     = var.vpc_id
  security_group_ids         = module.security_group
}

# =================================================================================

