locals {
  aws_for_fluentbit_cw_log_group_name = "/aws/eks/${var.eks_cluster_name}/aws-fluentbit-logs"
}

resource "helm_release" "aws-for-fluent-bit" {
  count            = var.enable_aws_for_fluent_bit ? 1 : 0

  name             = "aws-for-fluent-bit"
  description      = "A Helm chart to install the Fluent-bit Driver"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-for-fluent-bit"
  version          = var.aws_for_fluent_bit_chart_version
  namespace        = kubernetes_namespace.observability[0].metadata[0].name
  create_namespace = false

  set {
    name  = "cloudWatch.region"
    value = data.aws_region.this.name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.fluentbit_to_cloudwatch_irsa_role[0].iam_role_arn
    type  = "string"
  }

  set {
    name = "serviceAccount.name"
    value = "aws-for-fluent-bit"
    type = "string"
  }

  set {
    name  = "cloudWatchLogs.logGroupName"
    value = local.aws_for_fluentbit_cw_log_group_name
  }

  set {
    name  = "cloudWatchLogs.logGroupTemplate"
    value = ""
  }

  set {
    name  = "cloudWatchLogs.autoCreateGroup"
    value = false
  }

  set {
    name  = "cloudWatchLogs.region"
    value = data.aws_region.this.name
  }
}

module "fluentbit_to_cloudwatch_irsa_role" {
  count            = var.enable_aws_for_fluent_bit ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30.0"

  role_name_prefix                              = "aws-for-fluent-bit"
  role_policy_arns = {
    aws-for-fluent-bit = aws_iam_policy.aws_for_fluentbit[0].arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.observability[0].metadata[0].name}:aws-for-fluent-bit"]
    }
  }

  tags = local.tags
}

resource "aws_iam_policy" "aws_for_fluentbit" {
  count            = var.enable_aws_for_fluent_bit ? 1 : 0

  name_prefix = "aws-for-fluentbit"
  path        = "/"
  description = "Policy for aws_for_fluentbit role"

  policy = data.aws_iam_policy_document.aws_for_fluentbit[0].json

  tags = local.tags
}

data "aws_iam_policy_document" "aws_for_fluentbit" {
  count            = var.enable_aws_for_fluent_bit ? 1 : 0

  statement {
      sid    = "PutLogEvents"
      effect = "Allow"
      resources = [
        "arn:${data.aws_partition.this.partition}:logs:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:log-group:${local.aws_for_fluentbit_cw_log_group_name}:log-stream:*",
      ]

      actions = [
        "logs:PutLogEvents"
      ]
    }

  statement {

      sid    = "CreateCWLogs"
      effect = "Allow"
      resources = [
        "arn:${data.aws_partition.this.partition}:logs:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:log-group:${local.aws_for_fluentbit_cw_log_group_name}:*",
      ]

      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutRetentionPolicy",
      ]
  }
}

resource "aws_cloudwatch_log_group" "aws_for_fluentbit" {
  count            = var.enable_aws_for_fluent_bit ? 1 : 0

  name              = local.aws_for_fluentbit_cw_log_group_name
  retention_in_days = try(var.aws_for_fluent_bit_cw_log_group_retention, 90)
  tags              = local.tags
}
