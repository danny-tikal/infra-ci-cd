# Set common variables for the environment. This is automatically pulled in in the root terragrunt.hcl configuration to
# feed forward to the child modules.
locals {
  environment = "platform-test-runner"
  vpc_cidr    = "10.165.0.0/16"
  private_subnets  = [cidrsubnet(local.vpc_cidr, 3, 1), cidrsubnet(local.vpc_cidr, 3, 2), cidrsubnet(local.vpc_cidr, 3, 3)]
  public_subnets   = [cidrsubnet(local.vpc_cidr, 3, 4), cidrsubnet(local.vpc_cidr, 3, 5), cidrsubnet(local.vpc_cidr, 3, 6)]



  CS_STAGE                        = "develop"
  EM_STAGE                        = "develop"
  MACHINE_TYPE                    = "dev"
  eds_rds_url = "eds-starters-test1.cluster-corbl4iztisv.eu-west-1.rds.amazonaws.com"
}
