# Set account-wide variables. These are automatically pulled in to configure the remote state bucket in the root
# terragrunt.hcl configuration.
locals {
  account_name   = "dannyk"
  aws_profile    = "explorium-208155336842"
  account_arn    = "208155336842"
}
