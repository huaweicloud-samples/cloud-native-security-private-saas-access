variable "name_prefix" {
  type    = string
  default = "consumer"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "subnet_id" {
  description = "消费方子网资源 id"
  type        = string
}

variable "secgroup_id" {
  description = "消费方安全组 ID"
  type        = string
}

variable "availability_zone" {
  type    = string
  default = "cn-north-4a"
}

variable "flavor" {
  type    = string
  default = "s6.large.2"
}

variable "admin_pass" {
  description = "虚机登录密码（建议通过 TF_VAR 环境变量提供）"
  type        = string
  sensitive   = true
}
