locals {
  cluster_name = "eks-${var.env_profile}"

  argocd_pass = data.kubernetes_secret.argocd_secret.data["password"]
}

data "aws_eks_cluster" "cluster" {
  name = local.cluster_name
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
resource "null_resource" "kubernetes_ns" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "kubectl apply -f resources/namespaces.yaml --overwrite=true"
  }

  depends_on = [
    null_resource.helm_secrets
  ]
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}


resource "null_resource" "helm_secrets" {
  triggers = {
    always_run = "${timestamp()}"
  }
provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name eks-${var.env_profile} && kubectl config use-context arn:aws:eks:eu-west-1:182893536443:cluster/eks-${var.env_profile} && kubectl delete secrets -l owner=helm --all-namespaces"
  }
}
resource "helm_release" "argocd-installation" {
  depends_on = [
    null_resource.helm_secrets,
    null_resource.istioctl
  ]
  namespace = "argocd"
  name       = "argocd"
  chart      = "./charts/argocd-installation"
  force_update = true
  replace = true
  values = [
    "${file("./charts/argocd-installation/values.yaml")}"
  ]
  set {
    name  = "namespace"
    value = "${var.env_profile}"
  }
  set {
    name  = "api_server"
    value = "https://kubernetes.default.svc"
  }
  set {
    name  = "github_repo_url"
    value = "https://github.com/explorium-ai/argocd.git"
  }
}
resource "null_resource" "argo-rollouts" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "kubectl apply -n argo-rollouts -f resources/argocd-rollouts/install.yaml"
  }

  depends_on = [
    helm_release.argocd-installation
  ]
}

resource "null_resource" "istioctl_install" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.7.2 TARGET_ARCH=x86_64 sh -"
  }

  depends_on = [
    null_resource.helm_secrets
  ]
}

resource "null_resource" "istioctl" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "./istio-1.7.2/bin/istioctl manifest install -f resources/istio/istio.yaml --force"
  }

  depends_on = [
    null_resource.istioctl_install
  ]
}

resource "null_resource" "istio-ingressgateway_config" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "kubectl annotate --overwrite service istio-ingressgateway -n istio-system service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout=\"3600\" service.beta.kubernetes.io/aws-load-balancer-ssl-cert=\"arn:aws:acm:eu-west-1:182893536443:certificate/10de7fff-15f4-4c1b-8326-81d3ce500274\" service.beta.kubernetes.io/aws-load-balancer-ssl-ports=\"https\" service.beta.kubernetes.io/aws-load-balancer-backend-protocol=tcp"
  }

  depends_on = [
    null_resource.istio-internal-ingressgateway
  ]
}


resource "null_resource" "istio-internal-ingressgateway" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "kubectl apply -f resources/istio-internal-ingressgateway/istio-internal-ingressgateway.yaml"
  }

  depends_on = [
    null_resource.istioctl
  ]
}

data "aws_security_group" "eks_asg" {
  filter {
    name   = "group-name"
    values = ["eks_${var.env_profile}_asg"]
  }

}


resource "null_resource" "istio-internal-ingressgateway_config" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "kubectl annotate --overwrite service istio-internal-ingressgateway -n istio-system service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout=\"3600\" service.beta.kubernetes.io/aws-load-balancer-ssl-cert=\"arn:aws:acm:eu-west-1:182893536443:certificate/6fe522c9-03e6-4e06-8334-0e61abee8fd2\" service.beta.kubernetes.io/aws-load-balancer-ssl-ports=\"https\" service.beta.kubernetes.io/aws-load-balancer-security-groups=${data.aws_security_group.eks_asg.id} service.beta.kubernetes.io/aws-load-balancer-backend-protocol=tcp"
    }

  depends_on = [
    null_resource.istio-internal-ingressgateway
  ]
}

data "kubernetes_service" "istio_internal_ingressgateway" {
  metadata {
    name = "istio-internal-ingressgateway"
    namespace = "istio-system"
  }
  depends_on = [
    null_resource.istio-internal-ingressgateway_config 
  ]
}

resource "aws_route53_record" "ninja" {
  zone_id = "Z047040315Z7C2HKIWJJP"
  name = "argocd-${var.env_profile}.int.explorium.ninja"
  type = "CNAME"
  records = [data.kubernetes_service.istio_internal_ingressgateway.status[0].load_balancer[0].ingress[0].hostname]
  ttl = "300"
  allow_overwrite = true
  depends_on = [
    helm_release.argocd-installation
  ]
}
data "kubernetes_secret" "argocd_secret" {
  metadata {
    name = "argocd-initial-admin-secret"
    namespace = "argocd"
  }

  depends_on = [
    helm_release.argocd-installation
  ]
}

resource "null_resource" "argocd_login" {
    triggers = {
    always_run = "${timestamp()}"
  }
provisioner "local-exec" {
    command = "argocd login ${aws_route53_record.ninja.name} --username admin --password ${local.argocd_pass} --grpc-web --insecure"
  }
}
resource "null_resource" "argocd_create_repo" {
    triggers = {
    always_run = "${timestamp()}"
  }
provisioner "local-exec" {
    command = "argocd repo add git@github.com:explorium-ai/argocd.git --ssh-private-key-path ~/.ssh/explorium.pem --upsert"
  }

  depends_on = [
    null_resource.argocd_login
  ]
}
resource "null_resource" "cluster-apps" {
  triggers = {
    always_run = "${timestamp()}"
  }
provisioner "local-exec" {
    command = "argocd app create cluster-apps --dest-namespace argocd --dest-server https://kubernetes.default.svc --repo git@github.com:explorium-ai/argocd.git --revision ${var.cluster_apps_revision} --path argocd/argocd-apps/cluster-apps --values values_${env_profile}.yaml --upsert && argocd proj add-source kube-system git@github.com:explorium-ai/argocd.git"
  }
  depends_on = [
    null_resource.argocd_login,
    null_resource.argocd_create_repo
  ]
}

provider "rabbitmq" {
  endpoint = "${var.rabbithost}"
  username = "${var.rabbit_username}"
  password = "${var.rabbit_admin_password}"
  insecure = true
}

resource "rabbitmq_vhost" "vhost" {
  name = "${var.env_profile}-${var.env_profile}"
}
resource "rabbitmq_vhost" "vhost_bus" {
  name = "bus"
}

resource "rabbitmq_user" "user" {
  name     = "${var.env_profile}-${var.env_profile}"
  password = "${var.rabbit_password}"
  tags     = ["administrator", "management"]
}

resource "rabbitmq_permissions" "permissions" {
  user  = "${var.env_profile}-${var.env_profile}"
  vhost = "${var.env_profile}-${var.env_profile}"

  permissions {
    configure = ".*"
    write     = ".*"
    read      = ".*"
  }

  depends_on = [
    rabbitmq_user.user,
    rabbitmq_vhost.vhost
  ]
}

resource "rabbitmq_permissions" "permissions_bus" {
  user  = "${var.env_profile}-${var.env_profile}"
  vhost = "bus"

  permissions {
    configure = ".*"
    write     = ".*"
    read      = ".*"
  }

  depends_on = [
    rabbitmq_user.user,
    rabbitmq_vhost.vhost_bus
  ]
}