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
  source = "git@github.com:explorium-ai/terraform.git//eks-template/jenkins-slave"
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
    public_subnets = ["fake_subnet1", "fake_subnet2", "fake_subnet3"]
  }
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  # GENERAL
  env_profile                 = "${local.env}"
  vpc_id                      = dependency.vpc.outputs.vpc_id
  subnet_ids                  = dependency.vpc.outputs.public_subnets
  accepted_cidrs              = [local.environment_vars.locals.vpc_cidr, "157.230.3.208/32", "161.35.42.238/32", local.region_vars.locals.destination_p81_cidr]
  region                      = "${local.region}"
  jenkins_master_ip           = "jenkins.explorium.ai"
  master_jenkins_sg_name_tag  = "jenkins-master-sg"
}
