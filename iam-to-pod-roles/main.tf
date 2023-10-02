locals {
  tags = merge(var.tags, {
    Terraform = "true"
  })

  s3_access_resources = concat([
    for value in var.s3_bucket_name_list : "arn:aws:s3:::${value}"
    ],
    [
      for value in var.s3_bucket_name_list : "arn:aws:s3:::${value}/*"
  ])

}