
resource "aws_iam_user" "eks" {
  name = "k8s-${var.env_profile}-cluster-user"
}

resource "aws_iam_access_key" "eks" {
  user    = aws_iam_user.eks.name
}

resource "aws_iam_user_policy" "explorium_data_s3_policy" {
  name        = "k8s-${var.env_profile}-explorium.data.${var.env_profile}_s3_policy"
  user        = "k8s-${var.env_profile}-cluster-user"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "arn:aws:s3:::*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::explorium.data.${var.env_profile}/*",
                "arn:aws:s3:::explorium.data.${var.env_profile}",
                "arn:aws:s3:::${var.region}-enrichment-manager-bucket-develop/*",
                "arn:aws:s3:::${var.region}-enrichment-manager-bucket-develop"
            ]
        }
    ]
})
}
