terraform {
  backend "s3" {
    bucket         = "self-runner-infra-test"
    region         = "eu-west-1"
    key            =  "terraform.tfstate"
  }
}