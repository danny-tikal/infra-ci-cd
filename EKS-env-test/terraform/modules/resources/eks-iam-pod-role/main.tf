resource "aws_iam_role" "eks" {
name = "eks-${var.env_profile}-${var.service_account_name}-role"
assume_role_policy =  templatefile("oidc_assume_role_policy.json", { OIDC_ARN = var.aws_iam_openid_connect_provider_arn, OIDC_URL = replace(var.aws_iam_openid_connect_provider_url, "https://", ""), NAMESPACE = var.service_account_namespace, SA_NAME = var.service_account_name })
tags = {
        Environment = var.env_profile
        Type        = "eks-${var.env_profile}"
        Name        = "eks-${var.env_profile}-${var.service_account_name}"
}

}

resource "aws_iam_policy" "eks" {
  name   = "eks-${var.env_profile}-${var.service_account_name}-policy"
  path   = "/"
  policy = var.policy
}

resource "aws_iam_role_policy_attachment" "eks" {
  role       = aws_iam_role.eks.name
  policy_arn = aws_iam_policy.eks.arn
  depends_on = [aws_iam_role.eks]
}
