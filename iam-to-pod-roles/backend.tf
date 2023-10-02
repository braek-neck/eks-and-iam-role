# BACKEND
terraform {
  backend "s3" {
    bucket         = "487307228232-us-east-1-terraform-state"
    key            = "iam-roles/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locktable"
    encrypt        = true
  }
}