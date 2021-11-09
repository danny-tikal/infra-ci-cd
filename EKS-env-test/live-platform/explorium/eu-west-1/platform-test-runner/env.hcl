# Set common variables for the environment. This is automatically pulled in in the root terragrunt.hcl configuration to
# feed forward to the child modules.
locals {
  environment = "platform-test-runner"
  vpc_cidr    = "10.162.0.0/16"
  private_subnets = ["10.162.32.0/19", "10.162.64.0/19", "10.162.96.0/19"]
  public_subnets = ["10.162.128.0/19", "10.162.160.0/19", "10.162.192.0/19"]
  CS_STAGE                        = "develop"
  EM_STAGE                        = "develop"
  MACHINE_TYPE                    = "dev"
  eds_rds_url = "eds-starters-test1.cluster-corbl4iztisv.eu-west-1.rds.amazonaws.com"
}
