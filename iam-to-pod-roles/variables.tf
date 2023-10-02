variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}

variable "role_name" {
  description = "IAM rile name"
  type        = string
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace name, where pod will be run"
  type        = string
}

variable "kubernetes_serviceaccount_name" {
  description = "ServiceAccount name"
  type        = string
}

variable "s3_bucket_name_list" {
  description = "s3 bucket name list or '*' for policy"
  type        = list(string)
}