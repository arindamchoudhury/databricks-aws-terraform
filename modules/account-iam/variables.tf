variable "region" {
  type        = string
  description = "AWS region — used only by the generated aws provider; this layer creates no AWS resources"
}

variable "iam" {
  type = object({
    users = list(object({ user_name = string, display_name = string }))
    groups = list(object({ name = string, members = list(string) }))
  })
  description = "Account-level users and groups (from iam.json)"
}
