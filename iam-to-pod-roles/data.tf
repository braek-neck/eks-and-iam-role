data "aws_partition" "this" {}
data "aws_caller_identity" "this" {}

data "aws_eks_cluster" "eks" {
  name = var.eks_cluster_name
}

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