eks_cluster_name    = "my-test-cluster"
eks_cluster_version = "1.27"

eks_cluster_endpoint_public_access = true

eks_vpc_id                   = "vpc-0a71cdfc48e192403"
eks_subnet_ids               = ["subnet-0aa3cc34399db57f4", "subnet-09300a44fe36b111c", "subnet-06dca0e6e52c41b2a"]
eks_control_plane_subnet_ids = ["subnet-0cb6ce507b3bc137b", "subnet-072ea9a0ec72a841f", "subnet-06871733e2b1c6001"]

eks_managed_node_groups = {
  main = {
    min_size     = 1
    max_size     = 3
    desired_size = 2

    instance_types = ["t3.medium"]
  }
}

enable_aws_load_balancer_controller = true
alb_controller_target_revision      = "1.6.0"

enable_cluster_autoscaler          = true
cluster_autoscaler_target_revision = "9.29.1"

tags = {
  Department  = "OPS"
  Project     = "ABC"
  Environment = "Dev"
}