provider "aws" {}

data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${data.aws_caller_identity.this.account_id}-${data.aws_region.this.name}-terraform-state"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Environment = "Dev"
    Owner       = "OPS department"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-locktable"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "backend_backet" {
  value = <<BACKEND
  terraform {
  backend "s3" {
    bucket         = "${aws_s3_bucket.terraform_state.bucket}"
    key            = "STACKNAME/terraform.tfstate"
    region         = "${data.aws_region.this.name}"
    dynamodb_table = "${aws_dynamodb_table.terraform_state_lock.name}"
    encrypt        = true
  }
}
BACKEND
}