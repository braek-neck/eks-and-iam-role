locals {
  tags = merge(var.tags, {
    Terraform = "true"
  })
}

resource "kubernetes_namespace" "observability" {
  count = (var.enable_aws_cloudwatch_metrics || var.enable_aws_for_fluent_bit) ? 1 : 0

  depends_on = [module.eks]

  metadata {
    annotations = {
      name = "observability"
    }

    name = "observability"
  }
}

resource "kubernetes_namespace" "ingress" {
  count            = var.enable_aws_load_balancer_controller ? 1 : 0
  depends_on = [module.eks]

  metadata {
    annotations = {
      name = "ingress"
    }

    name = "ingress"
  }
}

resource "kubernetes_namespace" "cluster_autoscaler" {
  count            = var.enable_cluster_autoscaler ? 1 : 0
  depends_on = [module.eks]

  metadata {
    annotations = {
      name = "cluster-autoscaler"
    }

    name = "cluster-autoscaler"
  }
}