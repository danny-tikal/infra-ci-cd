locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  lily_creds = yamldecode("${get_terragrunt_dir()}/creds/lily_creds.yml.encrypted")
  aws_creds = yamldecode("${get_terragrunt_dir()}/creds/aws_creds.yml.encrypted")
  auth0_creds = yamldecode("${get_terragrunt_dir()}/creds/auth0_creds.yml.encrypted")

  # Extract out common variables for reuse
  env = local.environment_vars.locals.environment
  region = local.region_vars.locals.aws_region
}

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "../../../../../terraform//eks-template/app-components"
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

dependency "redis" {
  config_path = "../redis"

  # Configure mock outputs for the `validate` command that are returned when there are no outputs available (e.g the
  # module hasn't been applied yet.
  # https://terragrunt.gruntwork.io/docs/features/execute-terraform-commands-on-multiple-modules-at-once/#unapplied-dependency-and-mock-outputs
  mock_outputs_allowed_terraform_commands = ["validate","plan"]
  mock_outputs = {
    redis_endpoint = "fake-redis_endpoint"
  }
}

dependency "rabbitmq" {
  config_path = "../rabbitmq"

  # Configure mock outputs for the `validate` command that are returned when there are no outputs available (e.g the
  # module hasn't been applied yet.
  # https://terragrunt.gruntwork.io/docs/features/execute-terraform-commands-on-multiple-modules-at-once/#unapplied-dependency-and-mock-outputs
  mock_outputs_allowed_terraform_commands = ["validate","plan"]
  mock_outputs = {
    rabbitmq_endpoint = "fake-rabbitmq_endpoint"
    rabbitmq_celery_broker_url = "rabbitmq_celery_broker_url"
    rabbitmq_flower_broker_url = "rabbitmq_flower_broker_url"
  }
}

dependency "rds-postgres" {
  config_path = "../rds-postgres"

  # Configure mock outputs for the `validate` command that are returned when there are no outputs available (e.g the
  # module hasn't been applied yet.
  mock_outputs_allowed_terraform_commands = ["validate","plan"]
  mock_outputs = {
    rds_endpoint = "fake-rds_endpoint"
  }
}

dependency "eks" {
  config_path = "../eks"
  skip_outputs = true
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  lily_creds = local.lily_creds
  aws_creds = local.aws_creds
  auth0_creds = local.auth0_creds

  # GENERAL
  env_profile                 = "${local.env}"
  region                      = "${local.region}"
  vpc_id                      = dependency.vpc.outputs.vpc_id
  subnet_ids                  = dependency.vpc.outputs.private_subnets
  redis_endpoint              = dependency.redis.outputs.redis_endpoint
  rds_endpoint                = dependency.rds-postgres.outputs.rds_endpoint
  AUTH0_DOMAIN                = "explorium.auth0.com"

  # APPLICATION
  app_database_name               = "autoai"
  CS_STAGE                        = local.environment_vars.locals.CS_STAGE
  EM_STAGE                        = local.environment_vars.locals.EM_STAGE
  RT_CELERY_RESULT_BACKEND        = "rpc://"
  SHARED_VOLUME                   = "/opt/explorium/shared"
  MACHINE_TYPE                    = local.environment_vars.locals.MACHINE_TYPE
  PROMETHEUS_USERNAME             = ""
  PROMETHEUS_PASSWORD             = ""
  github_webhook_secret           = "8ebedf8847660d49e3922c38af1f263282077d1c"
  rabbitmq_celery_broker_url      = dependency.rabbitmq.outputs.rabbitmq_celery_broker_url
  rabbitmq_flower_broker_url      = dependency.rabbitmq.outputs.rabbitmq_flower_broker_url
}
