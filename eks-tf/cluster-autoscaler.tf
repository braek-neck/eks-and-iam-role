resource "helm_release" "cluster_autoscaler" {
  count            = var.enable_cluster_autoscaler ? 1 : 0
  name             = "aws-cluster-autoscaler"
  description      = "A Helm chart to deploy cluster-autoscaler"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  version          = var.cluster_autoscaler_target_revision
  namespace        = "kube-system"
  create_namespace = false

  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "awsRegion"
    value = data.aws_region.this.name
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.cluster_autoscaler_irsa_role[0].iam_role_arn
    type  = "string"
  }
}

module "cluster_autoscaler_irsa_role" {
  count   = var.enable_cluster_autoscaler ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30.0"

  role_name                        = "${var.eks_cluster_name}-cluster-autoscaler-role"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-cluster-autoscaler"]
    }
  }

  tags = local.tags
}

