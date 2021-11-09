
terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.14"
    }
  }
  required_version = ">= 0.14"
}