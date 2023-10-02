module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  cluster_endpoint_public_access       = var.eks_cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.eks_cluster_endpoint_public_access_cidrs

  vpc_id                   = var.eks_vpc_id
  subnet_ids               = var.eks_subnet_ids
  control_plane_subnet_ids = var.eks_control_plane_subnet_ids

  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  eks_managed_node_groups = var.eks_managed_node_groups

  # aws-auth configmap
  manage_aws_auth_configmap = true
  aws_auth_roles            = var.aws_auth_roles
  aws_auth_users            = var.aws_auth_users
  aws_auth_accounts         = var.aws_auth_accounts

  tags = local.tags
}