role_name = "my-pod"

s3_bucket_name_list = [
  "drongo-test",
  "drongo-test2"
]

kubernetes_namespace           = "default"
kubernetes_serviceaccount_name = "my-pod-sa"

tags = {
  Department  = "OPS"
  Project     = "ABC"
  Environment = "Dev"
}