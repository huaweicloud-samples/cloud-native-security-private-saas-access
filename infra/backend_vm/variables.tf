variable "name_prefix" {
  type    = string
  default = "privsaas"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "subnet_id" {
  description = "后端虚机所在子网资源 id（huaweicloud_vpc_subnet.this.id）"
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
  description = "虚机登录密码（需满足复杂度，建议通过 TF_VAR 环境变量提供，不要写入文件）"
  type        = string
  sensitive   = true
}
