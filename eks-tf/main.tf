locals {
  tags = merge(var.tags, {
    Terraform = "true"
  })
}