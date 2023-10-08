resource "helm_release" "aws_cloudwatch_metrics" {
  count            = var.enable_aws_cloudwatch_metrics ? 1 : 0
  name             = "aws-cloudwatch-metrics"
  description      = "A Helm chart to deploy aws-cloudwatch-metrics project"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-cloudwatch-metrics"
  version          = var.aws_cloudwatch_metrics_chart_version
  namespace        = kubernetes_namespace.observability[0].metadata[0].name
  create_namespace = false

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_cloudwatch_metrics_irsa_role[0].iam_role_arn
    type  = "string"
  }

  set {
    name = "serviceAccount.name"
    value = "aws-cloudwatch-metrics"
    type = "string"
  }
}

module "aws_cloudwatch_metrics_irsa_role" {
  count   = var.enable_aws_cloudwatch_metrics ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30.0"

  role_name_prefix                              = "aws-cloudwatch-metrics"
  role_policy_arns = {
    CloudWatchAgentServerPolicy = "arn:${data.aws_partition.this.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.observability[0].metadata[0].name}:aws-cloudwatch-metrics", ]
    }
  }

  tags = local.tags
}