locals {
  cluster_name = "eks-${var.env_profile}"

  # istio_values = templatefile("${path.module}/resources/istio/values_template.yaml",{
  #   gwname = "${var.env_profile}-gateway",
  #   host = "${var.env_profile}-app.explorium.ai",
  #   jupytergwname = "jupyter-${var.env_profile}-gateway",
  #   jupyterhost = "jupyter.${var.env_profile}-app.explorium.ai",
  #   postgrehost = "${var.rds_url}",
  #   rabbithost = replace("${var.rabbithost}","https://","")
  #   redishost = "${var.redishost}",
  #   pgiprange = "${var.vpc_cidr}",
  #   internaljupyter = true,
  #   internaldataserviceflower = true,
  #   dataservice = true,
  #   dataserviceflowergwname = "data-service-flower-${var.env_profile}-gateway",
  #   dataserviceflowerhost = "data-service-flower-${var.env_profile}.int.explorium.ninja",
  #   mongohost = "${var.mongo_url}",
  #   edsrdshost = "${var.eds_rds_url}",
  #   iprange = "${var.vpc_cidr}",
  # })
  #on_demand = contains([var.worker_asg[0]],"demand") ? var.worker_asg[0] : var.worker_asg[1]
  #spot = contains([var.worker_asg[0]],"spot") ? var.worker_asg[0] : var.worker_asg[1]
  cluster_autoscaler_values = templatefile("${path.module}/resources/cluster_autoscaler/values_template.yaml",{
    spot_asg = var.worker_asg[1],
    demand_asg = var.worker_asg[0],
    env_profile = "${var.env_profile}"
    region = "${var.region}"
  })

  filebeat2_values = templatefile("${path.module}/resources/filebeat2/values_template.yaml",{
    env_profile = "${var.env_profile}"
    region = "${var.region}"
  })

  kubernetes_external_secrets_values = templatefile("${path.module}/resources/kubernetes_external_secrets/values_template.yaml",{
    env_profile = "${var.env_profile}"
    region = "${var.region}"
  })

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

data "kubernetes_secret" "argocd_secret" {
  metadata {
    name = "argocd-initial-admin-secret"
    namespace = "argocd"
  }
}

# resource "local_file" "istio_values" {
#     content     = local.istio_values
#     filename = "${path.module}/resources/istio/values.yaml"
# }

resource "null_resource" "argocd_login" {
provisioner "local-exec" {
    command = "argocd login argocd-${var.env_profile}.int.explorium.ninja --username admin --password ${local.argocd_pass} --grpc-web --insecure"
  }
}
resource "null_resource" "platform-apps" {
  triggers = {
    always_run = "${timestamp()}"
  }
provisioner "local-exec" {
    command = "argocd app create platform-apps --dest-namespace argocd --dest-server https://kubernetes.default.svc --repo git@github.com:explorium-ai/argocd.git --revision ${var.platform_apps_revision} --path argocd/argocd-apps/platform-apps --values values_${env_profile}.yaml --upsert && argocd proj add-source ${var.env_profile} git@github.com:explorium-ai/argocd.git && argocd proj add-source prometheus git@github.com:explorium-ai/argocd.git && argocd proj add-source dev-namespaces git@github.com:explorium-ai/argocd.git"
  }
  depends_on = [
    null_resource.argocd_login
  ]
}

# resource "null_resource" "platform-istio-override" {
#   triggers = {
#     always_run = "${timestamp()}"
#   }
# provisioner "local-exec" {
#     command = "argocd app set platform-istio-${var.env_profile} --dest-namespace ${var.env_profile} --dest-server https://kubernetes.default.svc --repo git@github.com:explorium-ai/argocd.git --revision ${var.platform_apps_revision} --path istio --values-literal-file ${path.module}/resources/istio/values.yaml"
#   }
#   depends_on = [
#     null_resource.platform-apps
#   ]
# }

resource "local_file" "cluster_autoscaler_values" {
    content     = local.cluster_autoscaler_values
    filename = "${path.module}/resources/cluster_autoscaler/values.yaml"
}
resource "local_file" "filebeat2_values" {
    content     = local.filebeat2_values
    filename = "${path.module}/resources/filebeat2/values.yaml"
}
resource "local_file" "kubernetes_external_secrets_values" {
    content     = local.kubernetes_external_secrets_values
    filename = "${path.module}/resources/kubernetes_external_secrets/values.yaml"
}

resource "null_resource" "cluster_autoscaler-override" {
  triggers = {
    always_run = "${timestamp()}"
  }
provisioner "local-exec" {
    command = "argocd app set cluster-autoscaler --dest-namespace kube-system --dest-server https://kubernetes.default.svc --repo git@github.com:explorium-ai/argocd.git --revision ${var.platform_apps_revision} --path environments/eks-platform-dev/cluster-autoscaler --values-literal-file ${path.module}/resources/cluster_autoscaler/values.yaml"
  }
  depends_on = [
    null_resource.platform-apps
  ]
}
resource "null_resource" "filebeat2-override" {
  triggers = {
    always_run = "${timestamp()}"
  }
provisioner "local-exec" {
    command = "argocd app set filebeat --dest-namespace kube-system --dest-server https://kubernetes.default.svc --repo git@github.com:explorium-ai/argocd.git --revision ${var.platform_apps_revision} --path filebeat2 --values-literal-file ${path.module}/resources/filebeat2/values.yaml"
  }
  depends_on = [
    null_resource.platform-apps
  ]
}
resource "null_resource" "kubernetes_external_secrets" {
  triggers = {
    always_run = "${timestamp()}"
  }
provisioner "local-exec" {
    command = "argocd app set kubernetes-external-secrets --dest-namespace kube-system --dest-server https://kubernetes.default.svc --repo git@github.com:explorium-ai/argocd.git --revision ${var.platform_apps_revision} --path kubernetes-external-secrets --values-literal-file ${path.module}/resources/kubernetes_external_secrets/values.yaml"
  }
  depends_on = [
    null_resource.platform-apps
  ]
}