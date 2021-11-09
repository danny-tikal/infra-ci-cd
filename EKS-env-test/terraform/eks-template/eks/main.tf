locals {
  cluster_name = "eks-${var.env_profile}"
  filebeat-secrets-value = {
    TOKEN        = yamldecode(data.aws_kms_secrets.filebeat.plaintext["filebeat"]).TOKEN
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.cluster.name
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE EKS CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "eks" {
  source          = "../../modules/resources/eks"
  cluster_name    = local.cluster_name
  cluster_version = "1.18"
  subnets         = var.private_subnets

  tags = {
    Environment = var.env_profile
    Type        = "eks-${var.env_profile}"
    Name        = "eks-cluster-${var.env_profile}"
  }

  vpc_id = var.vpc_id

  cluster_endpoint_private_access	      = true
  cluster_endpoint_public_access	      = true
  cluster_create_endpoint_private_access_sg_rule = true
  cluster_endpoint_private_access_cidrs	= var.accepted_cidrs

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups_launch_template = [
    {
    name                    = "spots"
    override_instance_types = var.spot_instance_types
    spot_instance_pools     = 8
    asg_max_size            = var.spot-max_size
    asg_min_size            = var.spot-min_size
    asg_desired_capacity    = var.spot-min_size # looks like doesn't affect after initial creation
    additional_security_group_ids = [aws_security_group.eks_asg.id]
    kubelet_extra_args      = "--node-labels=node=spot,node.kubernetes.io/lifecycle=spot"
    }
  ]


  worker_groups = [
    {
      name                          = "on-demand"
      instance_type                 = var.ondemand_instance_types
      additional_userdata           = ""
      asg_desired_capacity          = var.demand-min_size
      asg_min_size                  = var.demand-min_size
      asg_max_size                  = var.demand-max_size
      additional_security_group_ids = [aws_security_group.eks_asg.id]
      kubelet_extra_args      = "--node-labels=node=ondemand"
    }
  ]
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
    {
      rolearn  = "arn:aws:iam::${var.aws_account}:role/eks-${var.env_profile}_access_role"
      username = "eks-${var.env_profile}_access_role"
      groups   = ["system:masters"]
    }
  ]
  # Map users is being overwritten
  map_users = [
    {
      groups   = ["system:masters"]
      userarn =  "arn:aws:iam::182893536443:user/boris.avney"
      username = "boris.avney"
    },
    {
      groups   = ["system:masters"]
      userarn =  "arn:aws:iam::182893536443:user/oren.levi"
      username = "oren.levi"
    },
    {
      groups   = ["system:masters"]
      userarn =  "arn:aws:iam::182893536443:user/AmazonEC2ContainerRegistryPowerUser"
      username = "AmazonEC2ContainerRegistryPowerUser"
    },
    {
      groups   = ["system:masters"]
      userarn =  "arn:aws:iam::182893536443:user/bohdan"
      username = "bohdan"
    },
    {
      groups   = ["system:masters"]
      userarn =  "arn:aws:iam::182893536443:user/matthew.buhagiar"
      username = "matthew.buhagiar"
    },
    {
      groups   = ["system:masters"]
      userarn =  "arn:aws:iam::182893536443:user/dan.kushner"
      username = "dan.kushner"
    },
    {
      groups   = ["system:masters"]
      userarn =  "arn:aws:iam::182893536443:user/rony.lutsky"
      username = "rony.lutsky"
    },
    {
      groups   = ["system:masters"]
      userarn =  "arn:aws:iam::182893536443:user/eric"
      username = "eric"
    },
    {
      groups   = ["system:masters"]
      userarn =  "arn:aws:iam::182893536443:user/adi.knafo"
      username = "adi.knafo"
    },
    {
      groups   = ["system:masters"]
      userarn =  "arn:aws:iam::182893536443:user/yehonatan.weinberger"
      username = "yehonatan.weinberger"
    },
    {
      groups   = ["system:masters"]
      userarn =  "arn:aws:iam::182893536443:user/sag"
      username = "sag"
    },
    {
      groups   = ["system:masters"]
      userarn =  "arn:aws:iam::182893536443:user/Shai.Roitman"
      username = "Shai.Roitman"
    },
    {
      groups   = ["system:masters"]
      userarn =  "arn:aws:iam::182893536443:user/or.kramer"
      username = "or.kramer"
    },
    {
      groups   = ["system:masters"]
      userarn =  "arn:aws:iam::182893536443:user/amitai.getzler"
      username = "amitai.getzler"
    }
  ]
}

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

# #### DEV Credentials
# resource "kubernetes_cluster_role" "dev_role" {
#   metadata {
#     name = "dev-role"
#   }

#   rule {
#     api_groups = ["apps","batch","extensions"]
#     resources  = ["configmaps", "cronjobs","deployments","events","ingresses","jobs","pods","pods/attach","pods/exec","pods/log","pods/portforward","secrets","services"]
#     verbs      = ["describe","get","list"]
#   }
# }
# resource "kubernetes_cluster_role_binding" "dev_role_binding" {
#   metadata {
#     name = "dev-role-binding"
#   }
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = kubernetes_cluster_role.dev_role.metadata[0].name
#   }
#   subject {
#     kind      = "User"
#     name      = "system:developer"
#   }
# }

### DATA --------------
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "tls_certificate" "cluster" {
  url = module.eks.cluster_oidc_issuer_url
}
data "aws_region" "current" {}
resource "aws_iam_openid_connect_provider" "eks" {
  url = module.eks.cluster_oidc_issuer_url

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [data.tls_certificate.cluster.certificates.0.sha1_fingerprint]

  tags = {
    Environment = var.env_profile
    Type        = "eks-${var.env_profile}"
    Name        = "eks-${var.env_profile}-identity-provider"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE AWS SECRETS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "filebeat" {
  name = "k8s-${var.env_profile}-filebeat-app-secret"
  recovery_window_in_days = 7
}

data "aws_kms_secrets" "filebeat" {
  secret {
    name    = "filebeat"
    payload = file(var.filebeat_creds)
  }
}

resource "aws_secretsmanager_secret_version" "filebeat" {
  secret_id     = aws_secretsmanager_secret.filebeat.id
  secret_string = jsonencode(local.filebeat-secrets-value)
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE SECURITY GROUPS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "eks_asg" {
  name = "eks_${var.env_profile}_asg"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = var.accepted_cidrs
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    description     = "Egress rule"
  }

  tags = {
    Name = "eks_${var.env_profile}_asg"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE IAM EKS POD ROLES
# ---------------------------------------------------------------------------------------------------------------------

## =============================== kubernetes-external-secrets-role ==================================
data "aws_iam_policy_document" "kubernetes-external-secrets" {
  statement {
    sid = "VisualEditor0"
    effect = "Allow"

    resources = [
      "*",
    ]

    actions = [ 
                "secretsmanager:GetRandomPassword",
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
               ]
  }
}

module "eks-iam-pod-role" {
  source                              = "../../modules/resources/eks-iam-pod-role"

  env_profile                         = var.env_profile
  service_account_name                = "kubernetes-external-secrets"
  service_account_namespace           = "kube-system"
  policy                              = data.aws_iam_policy_document.kubernetes-external-secrets.json
  aws_iam_openid_connect_provider_arn = aws_iam_openid_connect_provider.eks.arn
  aws_iam_openid_connect_provider_url = aws_iam_openid_connect_provider.eks.url
  
  depends_on                          = [aws_iam_openid_connect_provider.eks]

}
## =============================== kubernetes-external-secrets-role ==================================

## =============================== external-dns-role =================================================
data "aws_iam_policy_document" "external-dns" {
  statement {
    effect = "Allow"

    resources = [
      "arn:aws:route53:::hostedzone/Z047040315Z7C2HKIWJJP",
    ]

    actions = [ 
                "route53:ChangeResourceRecordSets"
               ]
  }
  statement {
    effect = "Allow"

    resources = [
      "*",
    ]

    actions = [ 
                "route53:ListHostedZones",
                "route53:ListResourceRecordSets"
               ]
  }
}

module "eks-iam-pod-role-external-dns" {
  source                              = "../../modules/resources/eks-iam-pod-role"

  env_profile                         = var.env_profile
  service_account_name                = "external-dns"
  service_account_namespace           = "kube-system"
  policy                              = data.aws_iam_policy_document.external-dns.json
  aws_iam_openid_connect_provider_arn = aws_iam_openid_connect_provider.eks.arn
  aws_iam_openid_connect_provider_url = aws_iam_openid_connect_provider.eks.url
  
  depends_on                          = [aws_iam_openid_connect_provider.eks]

}
## =============================== external-dns-role =================================================

## =============================== cluster-autoscaler-role =================================================
data "aws_iam_policy_document" "cluster-autoscaler" {
  statement {
    effect = "Allow"

    resources = [
      "*",
    ]

    actions = [ 
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:UpdateAutoScalingGroup",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "autoscaling:DescribeTags",
                "autoscaling:DescribeLaunchConfigurations",
                "ec2:DescribeLaunchTemplateVersions"
               ]
  }
}

module "eks-iam-pod-role-cluster-autoscaler" {
  source                              = "../../modules/resources/eks-iam-pod-role"

  env_profile                         = var.env_profile
  service_account_name                = "cluster-autoscaler"
  service_account_namespace           = "kube-system"
  policy                              = data.aws_iam_policy_document.cluster-autoscaler.json
  aws_iam_openid_connect_provider_arn = aws_iam_openid_connect_provider.eks.arn
  aws_iam_openid_connect_provider_url = aws_iam_openid_connect_provider.eks.url
  
  depends_on                          = [aws_iam_openid_connect_provider.eks]

}
## =============================== cluster-autoscaler-role =================================================
