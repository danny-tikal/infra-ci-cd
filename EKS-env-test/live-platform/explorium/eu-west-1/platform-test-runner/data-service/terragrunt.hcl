locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  mongodb_creds = yamldecode("${get_terragrunt_dir()}/creds/mongodb_creds.yml.encrypted")
  eds_rds_creds = yamldecode("${get_terragrunt_dir()}/creds/eds_rds_creds.yml.encrypted")
  authorization_service_creds = yamldecode("${get_terragrunt_dir()}/creds/authorization_service_creds.yml.encrypted")
  relic_license_key = yamldecode("${get_terragrunt_dir()}/creds/relic_license_key.yml.encrypted")
 
  # Extract out common variables for reuse
  env = local.environment_vars.locals.environment
  region = local.region_vars.locals.aws_region
}

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git@github.com:explorium-ai/terraform.git//eks-template/data-service"
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

dependency "rabbitmq" {
  config_path = "../rabbitmq"

  # Configure mock outputs for the `validate` command that are returned when there are no outputs available (e.g the
  # module hasn't been applied yet.
  # https://terragrunt.gruntwork.io/docs/features/execute-terraform-commands-on-multiple-modules-at-once/#unapplied-dependency-and-mock-outputs
  mock_outputs_allowed_terraform_commands = ["validate","plan"]
  mock_outputs = {
    rabbitmq_celery_broker_url = "fake-rabbitmq_celery_broker_url"
  }
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  mongodb_creds = local.mongodb_creds
  eds_rds_creds = local.eds_rds_creds
  authorization_service_creds = local.authorization_service_creds
  relic_license_key = local.relic_license_key
  
  # GENERAL
  env_profile          = "${local.env}"
  db_subnet_group_name = ""
  vpc_id               = dependency.vpc.outputs.vpc_id
  subnet_ids           = dependency.vpc.outputs.private_subnets
  rabbitmq_celery_broker_url = dependency.rabbitmq.outputs.rabbitmq_celery_broker_url
  # MONGODB
  engine                          = "docdb"
  availability_zones              = ["${local.region}a", "${local.region}b", "${local.region}c"]
  backup_retention_period         = 7
  preferred_backup_window         = "02:00-04:00"
  preferred_maintenance_window    = "sat:01:00-sat:01:30"
  docdb_engine_version            = "4.0.0"
  storage_encrypted               = true
  deletion_protection             = true
  enabled_cloudwatch_logs_exports = ["audit", "profiler"]
  skip_final_snapshot             = true

  instance_class = "db.r5.large"
  mongodb_sec_group_rules_list = [
    {
      description = "${local.env} vpc cidr access"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = [local.environment_vars.locals.vpc_cidr]
    },
    {
      description = "vpn cidr access"
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      cidr_block = [local.region_vars.locals.destination_p81_cidr]
    }
  ]
}
