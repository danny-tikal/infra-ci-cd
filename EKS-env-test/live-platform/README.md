[![Maintained by Devops Team](https://cdn-coepj.nitrocdn.com/wfkiesSEwVfWQNLPjWDvKANpXMZpUZbv/assets/static/optimized/rev-c5f12d2/wp-content/themes/tg/assets/images/general/explorium-logo.svg)](https://explorium.ai)

# EKS Clusters Configuration of Explorium

This repo, along with the [explorium terraform](https://github.com/explorium-ai/terraform), define the file/folder structure
you can use with [Terragrunt](https://github.com/gruntwork-io/terragrunt) to keep our
[Terraform](https://www.terraform.io) code DRY. For background information, check out the [Keep your Terraform code
DRY](https://github.com/gruntwork-io/terragrunt#keep-your-terraform-code-dry) section of the Terragrunt documentation.

This repo shows how to use the modules from the [explorium terraform](https://github.com/explorium-ai/terraform) repo to
deploy a VPC, EKS, and additional app-components on different environments, all without duplicating any of the Terraform code. That's because there is just a single copy of
the Terraform code, defined in the [explorium terraform - /eks-template](https://github.com/explorium-ai/terraform/tree/master/eks-template) repo, and in this repo, we solely define `terragrunt.hcl` files that reference that code (at a specific version, too, if you decide) and fill in variables specific to each
environment.
## How do you deploy the infrastructure in this repo?

### Pre-requisites

1. Install [Terraform](https://www.terraform.io/) and [Terragrunt](https://github.com/gruntwork-io/terragrunt).
2. Configure your AWS credentials on your local machine.
### Deploying an EKS cluster

1. Copy and paste a cluster in an environment of your choice (e.g. `cp -R explorium/eu-west-1/<cluster_name>/. explorium/eu-west-1/<new_cluster_name>`))
2. `cd` into the the new cluster folder (e.g. `cd explorium/eu-west-1/<new_cluster_name>`).
3. Change the variables in `env.hcl` and relevant sub-modules based on the specific needs of the cluster. Remember to check available subnets in AWS.
4. If you are creating an EKS from scrach, make sure your'e using post-script-init and not post-script (post-script is deprecated).
5. `cd` into `vpc` folder, and run `terragrunt plan`.
6. If the plan looks good, run `terragrunt apply`.
7. When finished, Configure Perimeter81 using the manual in [Confluence](https://exploriumai.atlassian.net/wiki/spaces/CON/pages/1904574714/EKS+infra-as-code+-+new+cluster+-+VPC+and+VPN).
8. `cd` into `eks` folder, and run `terragrunt plan`.
9. If the plan looks good, run `terragrunt apply`.
10. `cd ..` back into the cluster folder, and run `terragrunt run-all plan --terragrunt-ignore-dependency-errors`. This is to see all the changes you're about to apply, this time applying all other modules after your machine has connection to the VPC through perimeter81.
11. If the plan looks good, run `terragrunt run-all apply --terragrunt-ignore-dependency-errors`.
### Testing the infrastructure after it's deployed

After each module is finished deploying, it will write outputs to the screen.
### Useful commands

1. Delete cache and lock files: `find . -type f -name ".terraform.lock.hcl" -prune -exec rm -rf {} \; && find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;`
2. Plan after changes in the template `--terragrunt-source-update`
## How is the code in this repo organized?

The code in this repo uses the following folder hierarchy:

```
account
 └ _global
 └ region
    └ _global
    └ environment
       └ resource
```

Where:

* **Account**: At the top level are each of our AWS accounts, such as `explorium`. Because we have everything deployed
   in a single AWS account, there will just be a single folder at the root.

* **Region**: Within each account, there will be one or more [AWS
  regions](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html), such as
  `us-east-1`, `eu-west-1`, and `ap-southeast-2`, where we've deployed resources. There may also be a `_global`
  folder that defines resources that are available across all the AWS regions in this account, such as IAM users,
  Route 53 hosted zones, and CloudTrail.

* **Environment**: Within each region, there will be one or more "environments", such as `qa`, `stage`, etc. Typically,
  an environment will correspond to a single [AWS Virtual Private Cloud (VPC)](https://aws.amazon.com/vpc/), which
  isolates that environment from everything else in that AWS account. There may also be a `_global` folder
  that defines resources that are available across all the environments in this AWS region, such as Route 53 A records,
  SNS topics, and ECR repos.

* **Resource**: Within each environment, we deploy all the resources for that environment, such as EC2 Instances, Auto
  Scaling Groups, EKS Clusters, Databases, Load Balancers, and so on. Note that all the Terraform code for all of these
  resources lives in the [explorium terraform repo](https://github.com/explorium-ai/terraform).

## Adding a new resource/microservice to clusters

1. Branch out from [explorium terraform](https://github.com/explorium-ai/terraform) with your `resource_name`.
2. Add the resource under `eks-template`. Make sure all the configuration is through generic variables.
3. Branch out from this repo, and add `resource_name/terragrunt.hcl` to all relevant clusters. Set the `ref` in the `source` variable to your branch name.
4. `cd` into your either your new resource in each cluster, or even the entire region/account 
   folders as it will not re-apply existing resources, and `terragrunt plan`.
5. If plan succeeded, merge both branches, remove `ref` line in `source` and `terragrunt apply`. 
## Creating and using root (account) level variables

In the situation where you have multiple AWS accounts or regions, you often have to pass common variables down to each
of your modules. Rather than copy/pasting the same variables into each `terragrunt.hcl` file, in every region, and in
every environment, you can inherit them from the `inputs` defined in the root `terragrunt.hcl` file.
