resource "helm_release" "alb_controller" {
  count            = var.enable_aws_load_balancer_controller ? 1 : 0
  name             = "aws-load-balancer-controller"
  description      = "A Helm chart to deploy aws-load-balancer-controller for ingress resources"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = var.alb_controller_chart_version
  namespace        = kubernetes_namespace.ingress[0].metadata[0].name
  create_namespace = false

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "region"
    value = data.aws_region.this.name
  }

  set {
    name  = "vpcId"
    value = var.eks_vpc_id
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.alb_controller_irsa_role[0].iam_role_arn
    type  = "string"
  }
}

module "alb_controller_irsa_role" {
  count   = var.enable_aws_load_balancer_controller ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30.0"

  role_name                              = "${var.eks_cluster_name}-alb-controller-role"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.ingress[0].metadata[0].name}:aws-load-balancer-controller", ]
    }
  }

  tags = local.tags
}

