variable "name_prefix" {
  description = "资源名称前缀"
  type        = string
  default     = "privsaas"
}

variable "tags" {
  description = "统一附加到资源的标签"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "VPC 网段"
  type        = string
  default     = "192.168.0.0/16"
}

variable "subnet_cidr" {
  description = "子网网段，需落在 vpc_cidr 内"
  type        = string
  default     = "192.168.1.0/24"
}

variable "availability_zone" {
  description = "子网与负载均衡所在可用区（单可用区基线，与独享型 ELB 可用区对齐）"
  type        = string
  default     = "cn-north-4a"
}
