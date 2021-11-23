# Include all settings from the root terragrunt.hcl file
#include {
#  path = find_in_parent_folders()
#}

locals {
  account = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  #proj    = read_terragrunt_config(find_in_parent_folders("proj.hcl"))

  # Extract the variables we need for easy access
  # account
  account_name = local.account.locals.account_name
  account_id   = local.account.locals.account_arn

  # region
  aws_region = local.region.locals.aws_region

  # env
  environment = local.env.locals.environment

  # project
  #project        = local.proj.locals.project
  #github_org     = local.proj.locals.github_org
  #github_repo     = local.proj.locals.github_repo

  # combo
  cluster_name   = "eks-${local.environment}"
  namespace      = "explorium-mgmt"
  admin_accounts = local.env.locals.admin_accounts
  admin_roles    = local.env.locals.admin_roles
  dev_roles      = local.env.locals.dev_roles
  #slice_size_private = min(length(dependency.vpc.outputs.private_subnets), 2 )
  #slice_size_public  = min(length(dependency.vpc.outputs.public_subnets), 2 )
  eks_api_allowed_cidrs = [ 
                          "172.41.0.0/16", 
                          "161.35.42.224/28", # Danny Home
                          "82.166.134.98/32", # haggai home
                          #"0.0.0.0/0"         # fails when not in office / tikal-office
                          ]

}

terraform {
  source = "tfr:///terraform-aws-modules/eks/aws?version=17.22.0"
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





#dependency "kms" {
#  config_path = "${get_parent_terragrunt_dir()}/${local.environment}/${local.aws_region}//kms"
#}


inputs = {
  vpc_id        = dependency.vpc.outputs.vpc_id
  subnets       =  concat( slice( dependency.vpc.outputs.private_subnets,0 ,
                                  min(length(dependency.vpc.outputs.private_subnets), 2 ) 
                            ) , 
                           slice( dependency.vpc.outputs.public_subnets , 0 ,
                                  min(length(dependency.vpc.outputs.public_subnets) , 2 )
                           )
                      )
  #kms_arn       = dependency.kms.outputs.kms_key_arn

  cluster_name    = local.cluster_name
  cluster_version = "1.21"
  manage_aws_auth	= false
  cluster_tags = {
    Environment = local.environment
    #GithubRepo  = "${local.github_org}/${local.github_repo}"
  }
  cluster_endpoint_private_access = true
  #cluster_endpoint_private_access_cidrs = 
  cluster_endpoint_public_access = true
  cluster_endpoint_public_access_cidrs  = local.eks_api_allowed_cidrs

  map_users = [
    for user in "${local.admin_accounts}" :
    {
      userarn  = "${format("arn:aws:iam::${local.account_id}:user/%s", user)}"
      username = "${format("%s", user)}"
      groups   = ["system:masters"]
    }
  ]

  # must map these roles so you can access the eks workloads in the ui with your SAML account
  # permissions may vary in prod environments
  map_roles = [
    for role in concat(local.admin_roles,local.dev_roles) :
    {
      rolearn  = "${format("arn:aws:iam::${local.account_id}:role/%s", role)}"
      username = "${format("%s", role)}"
      groups   = ["system:masters"]
    }
  ]
  # to setup this parameter set KMS key
  #cluster_encryption_config = [
  #  {
  #    provider_key_arn = dependency.kms.outputs.kms_key_arn
  #    resources        = ["secrets"]
  #  }
  #]

  node_groups = {
    generic_node_group = {
      desired_capacity = 3
      max_capacity     = 8
      min_capacity     = 1
      name_prefix      = "ng_${local.cluster_name}_"
      instance_types = ["t3.large","m4.4xlarge"]
      /* capacity_type  = "SPOT" */
      k8s_labels = {
        Environment = local.cluster_name
        InstanceTypes = "spot"
      }
      additional_tags = {
        Environment = local.cluster_name
      }
    },
    demo_node_group = {
      desired_capacity = 0
      max_capacity     = 1
      min_capacity     = 0
      name_prefix      = "demo-ng_${local.cluster_name}_"
      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
      k8s_labels = {
        Environment = local.cluster_name
        InstanceTypes = "spot"
      }
      additional_tags = {
        InstanceTypes = "spot"
      }
      taints = [
        {
          key    = "dedicated"
          value  = "demoGroup"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }
}
