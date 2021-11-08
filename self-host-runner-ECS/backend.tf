terraform {
  backend "s3" {
    bucket         = "self-host-runner-bucket-208155336842"
    region         = "eu-west-1"
    key            =  "terraform.tfstate"
  }
}