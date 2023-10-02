data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "487307228232-us-east-1-terraform-state"
    key    = "eks/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_region" "this" {}

data "aws_iam_policy_document" "access_to_s3" {

  statement {
    actions = ["s3:ListAllMyBuckets"]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "s3:*"
    ]
    resources = local.s3_access_resources
  }
}