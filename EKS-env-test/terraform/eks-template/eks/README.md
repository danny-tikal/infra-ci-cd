# EKS User Managment:

Command example:
```aws eks --region eu-west-1 update-kubeconfig --name eks-platform-stg --verbose --role-arn arn:aws:iam::182893536443:role/eks-platform-stg_admin_role```
```aws eks --region eu-west-1 update-kubeconfig --name eks-{cluster_name} --verbose --role-arn arn:aws:iam::182893536443:role/eks-{cluster_name}_{admin/dev}_role```

The following template creates the logic to be used for kubernetes and AWS combined for user managment.
This module creates the "admin" role, and the "system:developer" role (kubernetes user), taking in a certain AWS role arn.
In order to add a certain user to certain credentials in a certain EKS, you have to add it to a relevant group as described below.
These AWS groups allow users to assume the roles that are connected with specific users in kubernetes.

- `eks-${var.env_profile}-admins`
- `eks-${var.env_profile}-dev`

The kubernets cluster roles and cluster role bindings are managed through ArgoCD using `cluster-roles` helm chart.

Binding the roles to EKS:

```js
  map_roles                            = [
    {
      rolearn  = aws_iam_role.eks_admin_role.arn
      username = "admin"
      groups   = ["system:masters"]
    },
    {
      rolearn  = aws_iam_role.eks_dev_role.arn
      username = "system:developer"
      groups   = []
    },
    { //Jenkins role - unrelated
      rolearn  = "arn:aws:iam::${var.aws_account}:role/eks-${var.env_profile}_access_role"
      username = "eks-${var.env_profile}_access_role"
      groups   = ["system:masters"]
    }
  ]
```

Creating AWS groups that allow users to assume the roles mentioned above:

```python
#### GROUPS
resource "aws_iam_group" "eks_admins_group" {
  name = "eks-${var.env_profile}-admins"
}
resource "aws_iam_group" "eks_devs_group" {
  name = "eks-${var.env_profile}-dev"
}

#### ROLES
resource "aws_iam_role" "eks_admin_role" {
  name = "eks-${var.env_profile}_admin_role"
  assume_role_policy = "${file("assumerolepolicy.json")}"
}
resource "aws_iam_role" "eks_dev_role" {
  name = "eks-${var.env_profile}_dev_role"
  assume_role_policy = "${file("assumerolepolicy.json")}"
}

#### GROUPS POLICIES
resource "aws_iam_policy" "eks-admin-policy" {
  name        = "eks-${var.env_profile}-admins-policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowAssumeOrganizationAccountRole",
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Resource": aws_iam_role.eks_admin_role.arn
      }
    ]
  })
}
resource "aws_iam_policy" "eks-dev-policy" {
  name        = "eks-${var.env_profile}-devs-policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowAssumeOrganizationAccountRole",
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Resource": aws_iam_role.eks_dev_role.arn
      }
    ]
  })
}

#### GROUPS ATTACH ROLES
resource "aws_iam_group_policy_attachment" "group-attach-admin" {
  group      = aws_iam_group.eks_admins_group.name
  policy_arn = aws_iam_policy.eks-admin-policy.arn
}
resource "aws_iam_group_policy_attachment" "group-attach-dev" {
  group      = aws_iam_group.eks_devs_group.name
  policy_arn = aws_iam_policy.eks-dev-policy.arn
}
```