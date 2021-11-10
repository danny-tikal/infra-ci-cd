locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  # Extract out common variables for reuse
  env = local.environment_vars.locals.environment
}

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  #source = "../../../../../terraform//eks-template/vpc"
  source = "git@github.com:explorium-ai/terraform.git//eks-template/vpc"

  after_hook "after_hook" {
    commands     = ["apply", "plan"]
    execute      = ["echo", "Please create Perimeter81 Connection"]
    run_on_error = true
  }
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  env_profile                 = "${local.env}"
  vpc_cidr                    = "${local.environment_vars.locals.vpc_cidr}"
  private_subnets             = "${local.environment_vars.locals.private_subnets}"
  public_subnets              = "${local.environment_vars.locals.public_subnets}"
  customer_gw                 = "${local.region_vars.locals.customer_gw}"
  destination_p81_cidr        = "${local.region_vars.locals.destination_p81_cidr}"
  management_tgw_id           = "${local.region_vars.locals.management_tgw_id}"
  # To avoid storing a password in the code, set it as the environment variable TF_VAR_master_password
}
