locals {
  provider_arn = "arn:${data.aws_partition.this.partition}:iam::${data.aws_caller_identity.this.account_id}:oidc-provider/${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}"
}

module "iam_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30.0"

  role_name = "${var.role_name}-role"
  role_policy_arns = {
    access_to_s3 = aws_iam_policy.policy_access_s3.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = local.provider_arn
      namespace_service_accounts = ["${var.kubernetes_namespace}:${var.kubernetes_serviceaccount_name}"]
    }
  }

  tags = local.tags
}

resource "aws_iam_policy" "policy_access_s3" {
  name        = "${var.role_name}-policy"
  path        = "/"
  description = "Policy for ${var.role_name} role"

  policy = data.aws_iam_policy_document.access_to_s3.json

  tags = local.tags
}