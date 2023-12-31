variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.27`)"
  type        = string
}

variable "eks_cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "eks_cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_control_plane_subnet_ids" {
  description = "A list of subnet IDs where the EKS cluster control plane (ENIs) will be provisioned. Used for expanding the pool of subnets used by nodes/node groups without replacing the EKS control plane"
  type        = list(string)
}

variable "eks_subnet_ids" {
  description = "A list of private subnet IDs where the nodes/node groups will be provisioned. If `control_plane_subnet_ids` is not provided, the EKS cluster control plane (ENIs) will be provisioned in these subnets"
  type        = list(string)
}

variable "eks_vpc_id" {
  description = "ID of the VPC where the cluster security group will be provisioned"
  type        = string
}

variable "aws_auth_roles" {
  description = "List of role maps to add to the aws-auth configmap"
  type        = list(any)
  default     = []
}

variable "aws_auth_users" {
  description = "List of user maps to add to the aws-auth configmap"
  type        = list(any)
  default     = []
}

variable "aws_auth_accounts" {
  description = "List of account maps to add to the aws-auth configmap"
  type        = list(any)
  default     = []
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
  default     = {}
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = false
}

variable "alb_controller_chart_version" {
  description = "ALB controller chart version." # https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller
  type        = string
}

variable "cluster_autoscaler_chart_version" {
  description = "ALB controller chart version." #https://github.com/kubernetes/autoscaler/tree/master/charts
  type        = string
}

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster autoscaler add-on"
  type        = bool
  default     = false
}

variable "enable_aws_cloudwatch_metrics" {
  description = "Enable AWS Cloudwatch EKS metrics"
  type        = bool
  default     = false
}

variable "aws_cloudwatch_metrics_chart_version" {
  description = "AWS Cloudwatch EKS metrics chart version." #https://github.com/aws/eks-charts/blob/master/stable/aws-cloudwatch-metrics/README.md
  type        = string
}

variable "enable_aws_for_fluent_bit" {
  description = "Enable Fluent-bit"
  type        = bool
  default     = false
}

variable "aws_for_fluent_bit_chart_version" {
  description = "Fluent-bit chart version."  #https://github.com/aws/eks-charts/blob/master/stable/aws-for-fluent-bit/README.md
  type        = string
  default     = null
}

variable "aws_for_fluent_bit_cw_log_group_retention" {
  description = "CloudWatch log group retention"
  type = number
}