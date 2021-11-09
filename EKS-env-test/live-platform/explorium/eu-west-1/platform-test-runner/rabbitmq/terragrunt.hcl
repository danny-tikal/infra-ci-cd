locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  rabbitmq_creds = yamldecode("${get_terragrunt_dir()}/creds/rabbitmq_creds.yml.encrypted")
  rabbitmq_user_pass = yamldecode("${get_terragrunt_dir()}/creds/rabbitmq_user_pass.yml.encrypted")

  # Extract out common variables for reuse
  env = local.environment_vars.locals.environment
}

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "../../../../../terraform//eks-template/rabbitmq"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"

  # Configure mock outputs for the `validate` command that are returned when there are no outputs available (e.g the
  # module hasn't been applied yet.
  mock_outputs_allowed_terraform_commands = ["validate","plan"]
  mock_outputs = {
    vpc_id = "fake-vpc-id"
    private_subnets = ["fake_subnet1", "fake_subnet2", "fake_subnet3"]
  }
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  rabbitmq_creds = local.rabbitmq_creds
  rabbitmq_user_pass = local.rabbitmq_user_pass

  # GENERAL
  env_profile                 = "${local.env}"
  vpc_id                      = dependency.vpc.outputs.vpc_id
  subnet_ids                  = dependency.vpc.outputs.private_subnets
  # RABBITMQ
  rabbitmq_sg_description     = "Security group for Rabbitmq Brocker"
  rabbitmq_sec_group_rules_list = [
    {
      description              = "${local.env} vpc cidr access"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_block               = [local.environment_vars.locals.vpc_cidr]
    },
    {
      description              = "vpn cidr access"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      cidr_block               = [local.region_vars.locals.destination_p81_cidr]
    }
  ]

  broker_name                 = "${local.env}"
  engine_version              = "3.8.6"
  deployment_mode             = "CLUSTER_MULTI_AZ"
  engine_type                 = "RabbitMQ"
  host_instance_type          = "mq.m5.large"
  general_logs                = true
  # maintenance_window_start_time
  day_of_week                 = "SUNDAY"
  time_of_day                 = "02:00"
  time_zone                   = "UTC"
  publicly_accessible         = false

}
