locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract out common variables for reuse
  env = local.environment_vars.locals.environment
  region = local.region_vars.locals.aws_region
}

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "../../../../../terraform//eks-template/post-script-init"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "rabbitmq" {
  config_path = "../rabbitmq"

  # Configure mock outputs for the `validate` command that are returned when there are no outputs available (e.g the
  # module hasn't been applied yet.
  # https://terragrunt.gruntwork.io/docs/features/execute-terraform-commands-on-multiple-modules-at-once/#unapplied-dependency-and-mock-outputs
  mock_outputs_allowed_terraform_commands = ["validate","plan"]
  mock_outputs = {
    rabbitmq_endpoint = "fake-rabbitmq_endpoint"
    rabbit_username   = "fake-rabbit_username"
    rabbit_password   = "fake-rabbit_password"
    rabbit_admin_password   = "fake-rabbit_admin_password"
  }
}

dependency "eks" {
  config_path = "../eks"
  skip_outputs = true
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  # GENERAL
  env_profile                 = "${local.env}"
  region                      = "${local.region}"
  rabbithost                  = dependency.rabbitmq.outputs.rabbitmq_endpoint
  rabbit_username             = dependency.rabbitmq.outputs.rabbit_username
  rabbit_admin_password       = dependency.rabbitmq.outputs.rabbit_admin_password
  rabbit_password             = dependency.rabbitmq.outputs.rabbit_password
  cluster_apps_revision       = "develop"
}
