locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  rds_creds = yamldecode("${get_terragrunt_dir()}/creds/rds_creds.yml.encrypted")
  rds_ro_pass = yamldecode("${get_terragrunt_dir()}/creds/rds_ro_db_user.yml.yml.encrypted")

  # Extract out common variables for reuse
  env = local.environment_vars.locals.environment
  region = local.region_vars.locals.aws_region
}

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "../../../../../terraform//eks-template/rds-postgres"
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
  rds_creds                   = local.rds_creds

  # GENERAL
  env_profile                 = "${local.env}"
  vpc_id                      = dependency.vpc.outputs.vpc_id
  subnet_ids                  = dependency.vpc.outputs.private_subnets
  region                      = "${local.region}"
  # RDS-POSTGRESS
  database_name               =  "autoai"
  rds_sec_group_rules_list = [
    {
      description              = "default vpc cidr access"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      cidr_block               = [ "172.31.0.0/16" ]
    },
    {
      description              = "${local.env} vpc cidr access"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      cidr_block               = [local.environment_vars.locals.vpc_cidr]
    },
    {
      description              = "vpn cidr access"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      cidr_block               = [local.region_vars.locals.destination_p81_cidr]
    }
  ]

  engine                          = "aurora-postgresql"
  availability_zones              = ["${local.region}a", "${local.region}b", "${local.region}c"]
  backup_retention_period         = 7
  preferred_backup_window         = "02:00-04:00"
  preferred_maintenance_window    = "sat:01:00-sat:01:30"
  allow_major_version_upgrade     = false
  rds_engine_version              = 11.9
  storage_encrypted               = true
  deletion_protection             = true
  enabled_cloudwatch_logs_exports = ["postgresql"]
  skip_final_snapshot             = true
  replicas_count                  = 1
  instance_class                  = "db.t3.medium"
  performance_insights_enabled    = true

  db_config_params = {
      crete_ro_db_user  = true
      readonly_user_password = local.rds_ro_pass
    }

}
