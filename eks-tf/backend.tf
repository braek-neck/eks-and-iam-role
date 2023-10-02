# BACKEND
terraform {
  backend "s3" {
    bucket         = "XXXXXXXXXXX-us-east-1-terraform-state"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locktable"
    encrypt        = true
  }
}