locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract out common variables for reuse
  env = local.environment_vars.locals.environment
}

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "../../../../../terraform//eks-template/redis"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"

  # Configure mock outputs for the `validate` command that are returned when there are no outputs available (e.g the
  # module hasn't been applied yet.
  # https://terragrunt.gruntwork.io/docs/features/execute-terraform-commands-on-multiple-modules-at-once/#unapplied-dependency-and-mock-outputs
  mock_outputs_allowed_terraform_commands = ["validate","plan"]
  mock_outputs = {
    vpc_id = "fake-vpc-id"
    private_subnets = ["fake_subnet1", "fake_subnet2", "fake_subnet3"]
  }
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  # GENERAL
  env_profile                 = "${local.env}"
  vpc_id                      = dependency.vpc.outputs.vpc_id
  subnet_ids                  = dependency.vpc.outputs.private_subnets
  # ECC
  redis_engine_version        = "6.x" # at first run use 6.x , its aws bug. then change ti 6.0.5
  redis_sec_group_rules_list  = [
    {
      description              = "${local.env} vpc cidr access"
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      cidr_block               = [local.environment_vars.locals.vpc_cidr]
    },
    {
      description              = "vpn cidr access"
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      cidr_block               = [local.environment_vars.locals.vpc_cidr]
    }
  ]
  node_type                   = "cache.r5.large"
  parameter_group_name        = "default.redis6.x"
  maintenance_window          = "sat:09:30-sat:10:30"
  snapshot_window             = "07:00-08:00"
  snapshot_retention_limit    = 1
  number_cache_clusters       = 2
  automatic_failover_enabled  = true
  transit_encryption_enabled  = false
  at_rest_encryption_enabled  = true
  multi_az_enabled            = true
}
