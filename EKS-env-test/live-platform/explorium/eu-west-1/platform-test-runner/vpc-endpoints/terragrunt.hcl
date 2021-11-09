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
  source = "../../../../../terraform//eks-template/vpc-endpoints"
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
  owner                       = "${local.env}"
  vpc_id                      = dependency.vpc.outputs.vpc_id
  subnet_ids                  = dependency.vpc.outputs.private_subnets
  region                      = "${local.region}"
  
  # VPC ENDPOINTS
  
  ep_sec_group_rules_list = [
    {
      description              = "${local.env} vpc cidr access"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      cidr_block               = [local.environment_vars.locals.vpc_cidr]
    }
  ]

  # service_endpoints   = [ "ec2" ,"ecr.api" ,"ecr.dkr" ,"secretsmanager" ,"kms", "athena" ,"glue", "monitoring", "logs", "rds", "rds-data", "sns", "sqs", "ssm"]

  # Add to the service_endpoints list which services to use as VPC Service Endpoints

  service_endpoints   = [ "ec2" ]

  gateway_endpoints   = [ "s3", "dynamodb" ]

  route_tables        = ["${dependency.vpc.outputs.main_route_table}", "${dependency.vpc.outputs.private_route_table}", "${dependency.vpc.outputs.public_route_table}"]

}
