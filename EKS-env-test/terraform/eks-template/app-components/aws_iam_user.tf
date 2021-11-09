
resource "aws_iam_user" "eks" {
  name = "k8s-${var.env_profile}-cluster-user"
}

resource "aws_iam_access_key" "eks" {
  user    = aws_iam_user.eks.name
}

resource "aws_iam_user_policy" "pg_encryption_key_encrypt_decrypt" {
  name        = "k8s-${var.env_profile}-pg_encryption_key_encrypt_decrypt"
  user        = aws_iam_user.eks.name
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt",
                "kms:Encrypt"
            ],
            "Resource": "arn:aws:kms:${var.region}:182893536443:key/58e17d8b-8a9d-4511-beb4-52330bd86ac2"
        }
    ]
})
}

resource "aws_iam_user_policy" "dynamodb_tenants_service_tokens_policy" {
  name        = "k8s-${var.env_profile}-dynamodb_tenants_service_tokens_policy"
  user        = aws_iam_user.eks.name
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DescribeQueryScanBooksTable",
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:Scan"
            ],
            "Resource": "arn:aws:dynamodb:${var.region}:182893536443:table/tenants_service_tokens"
        }
    ]
})
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
                "arn:aws:s3:::sample-projects-directory/*",
                "arn:aws:s3:::sample-projects-directory",
                "arn:aws:s3:::explorium.data.${var.env_profile}/*",
                "arn:aws:s3:::explorium.data.${var.env_profile}",
                "arn:aws:s3:::${var.region}-enrichment-manager-bucket-develop/*",
                "arn:aws:s3:::${var.region}-enrichment-manager-bucket-develop"
            ]
        }
    ]
})
}

resource "aws_iam_user_policy" "firehost_em_policy" {
  name        = "k8s-${var.env_profile}-${var.env_profile}_firehost_em_policy"
  user        = aws_iam_user.eks.name
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "firehose:PutRecordBatch",
            "Resource": [
                "arn:aws:firehose:${var.region}:182893536443:deliverystream/monitoring-metrics-stream-develop",
                "arn:aws:firehose:${var.region}:182893536443:deliverystream/metrics-*-develop"
            ]
        }
    ]
})
}

resource "aws_iam_user_policy" "secretmanager-sftp" {
  name        = "k8s-${var.env_profile}-${var.env_profile}_secretmanager_sftp_policy"
  user        = aws_iam_user.eks.name
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": [
                "arn:aws:secretsmanager:${var.region}:182893536443:secret:sftp-connector-gpg-private-key",
                "arn:aws:secretsmanager:${var.region}:182893536443:secret:sftp-connector-gpg-public-key"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:ListSecrets",
            "Resource": "*"
        }
    ]
})
}