locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Extract out common variables for reuse

  filebeat_creds = yamldecode("${get_terragrunt_dir()}/creds/filebeat_creds.yml.encrypted")
  env = local.environment_vars.locals.environment
  account_arn = local.account_vars.locals.account_arn
  sg_id                       = "sg-0f4edea3de1d5fcdc"
  inst_types = ["m5a.4xlarge", "m5ad.4xlarge" , "m5.4xlarge", "m5d.4xlarge", "m5n.4xlarge", "m5dn.4xlarge", "m4.4xlarge"]
}

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  #source = "github.com/explorium-ai/terraform.git//eks-template/eks"
  #source = "git@github.com:explorium-ai/terraform.git//modules/resources/eks"
  source = "github.com/explorium-ai/terraform.git//modules/resources/eks"
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
  filebeat_creds              = local.filebeat_creds
  vpc_id                      = dependency.vpc.outputs.vpc_id
  private_subnets             = dependency.vpc.outputs.private_subnets
  spot_instance_types         = ["m5a.4xlarge", "m5ad.4xlarge" , "m5.4xlarge", "m5d.4xlarge", "m5n.4xlarge", "m5dn.4xlarge", "m4.4xlarge"]
  ondemand_instance_types     = "m4.4xlarge"
  env_profile                 = "${local.env}"
  aws_account                 = "${local.account_arn}"
  accepted_cidrs              = [local.environment_vars.locals.vpc_cidr, "157.230.3.208/32", "161.35.42.238/32", local.region_vars.locals.destination_p81_cidr]
  spot-max_size               = 2
  spot-min_size               = 1
  demand-max_size             = 2
  demand-min_size             = 1

  ### additional inputs for EKS module
  cluster_name                = "eks-${local.env}"
  cluster_version             = 1.21
  subnets                     = dependency.vpc.outputs.private_subnets
  #sg_id                       = "sg-0f4edea3de1d5fcdc"    #dependency.vpc.outputs.default_vpc_default_security_group_id

  worker_groups_launch_template = [
    {
    name                    = "spots"
    override_instance_types = ["m5a.4xlarge", "m5ad.4xlarge" , "m5.4xlarge", "m5d.4xlarge", "m5n.4xlarge", "m5dn.4xlarge", "m4.4xlarge"]
    spot_instance_pools     = 8
    asg_max_size            = 2
    asg_min_size            = 1
    asg_desired_capacity    = 1 # looks like doesn't affect after initial creation
    additional_security_group_ids = ["${local.sg_id}"]  ##aws_security_group.eks_asg.id]
    kubelet_extra_args      = "--node-labels=node=spot,node.kubernetes.io/lifecycle=spot"
    }
  ]


  worker_groups = [
    {
      name                          = "on-demand"
      instance_type                 = "m4.4xlarge"
      additional_userdata           = ""
      asg_desired_capacity          = 1
      asg_min_size                  = 1
      asg_max_size                  = 2
      additional_security_group_ids = ["${local.sg_id}"]     #[aws_security_group.eks_asg.id]
      #kubelet_extra_args      = "--node-labels=node=ondemand"
    }
  ]

}
