resource "aws_s3_bucket" "mybucket" {
  bucket = "explorium.data.${var.env_profile}"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    bucket_key_enabled = true
    }
  }

  tags = {
    Name        = "explorium.data.${var.env_profile}"
    Environment = var.env_profile
    Managed_by  = "Terraform"
    Owner       = var.env_profile
  }
}