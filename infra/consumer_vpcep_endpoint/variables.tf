
variable "name_prefix" {
  description = "资源名称前缀"
  type        = string
  default     = "consumer"
}

variable "tags" {
  description = "统一附加到资源的标签"
  type        = map(string)
  default     = {}
}

variable "endpoint_service_id" {
  description = "服务端终端节点服务 ID；留空时按 endpoint_service_name 查找"
  type        = string
  default     = ""
}

variable "endpoint_service_name" {
  description = "服务端终端节点服务名称，服务端输出 endpoint_service_name 或 endpoint_service_address 即为该值"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "消费方 VPC ID"
  type        = string
}

variable "network_id" {
  description = "消费方子网的网络 ID，取子网资源的 subnet_id 字段"
  type        = string
}

variable "ip_address" {
  description = "终端节点私网地址，留空表示自动分配"
  type        = string
  default     = null
}

variable "enable_dns" {
  description = "是否创建终端节点内网域名"
  type        = bool
  default     = true
}

variable "enable_whitelist" {
  description = "是否启用终端节点访问控制白名单"
  type        = bool
  default     = false
}

variable "whitelist" {
  description = "允许访问该终端节点的 IP 地址或网段列表"
  type        = list(string)
  default     = []
}

variable "private_zone_id" {
  description = "服务端输出的私网域名解析区域 ID；留空表示不写入解析记录"
  type        = string
  default     = ""
}

variable "private_zone_name" {
  description = "私网域名后缀，需与服务端保持一致"
  type        = string
  default     = "saas.internal"
}

variable "record_name" {
  description = "为本终端节点注册的域名前缀；留空表示不写入解析记录"
  type        = string
  default     = "saas"
}

variable "record_ttl" {
  description = "解析记录 TTL，单位秒"
  type        = number
  default     = 300
}
