role_name = "test-pod"

s3_bucket_name_list = [
  "drongo-test",
  "drongo-test2"
]

kubernetes_namespace           = "default"
kubernetes_serviceaccount_name = "nginx-deployment-sa"

tags = {
  Department  = "OPS"
  Project     = "ABC"
  Environment = "Dev"
}