
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

variable "vpc_id" {
  description = "承载 API 网关实例的 VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "API 网关实例所在子网 ID，取子网资源的 id 字段"
  type        = string
}

variable "availability_zones" {
  description = "可用区列表"
  type        = list(string)
  default     = ["cn-north-4a"]
}

variable "edition" {
  description = "API 网关专享版规格"
  type        = string
  default     = "BASIC"

  validation {
    condition = contains(
      ["BASIC", "PROFESSIONAL", "ENTERPRISE", "PLATINUM",
      "BASIC_IPV6", "PROFESSIONAL_IPV6", "ENTERPRISE_IPV6", "PLATINUM_IPV6"],
      var.edition
    )
    error_message = "规格仅支持专享版系列：BASIC / PROFESSIONAL / ENTERPRISE / PLATINUM（及对应 IPV6 变体）。"
  }
}

variable "access_cidrs" {
  description = "允许访问 API 网关的网段列表，写入实例安全组"
  type        = list(string)
  default     = []
}

variable "api_name" {
  description = "对外暴露的 API 名称"
  type        = string
  default     = "private-echo"
}

variable "api_request_protocol" {
  description = "API 对外请求协议"
  type        = string
  default     = "HTTPS"
}

variable "api_request_method" {
  description = "API 请求方法"
  type        = string
  default     = "ANY"
}

variable "api_request_path" {
  description = "API 请求路径"
  type        = string
  default     = "/v1/saas"
}

variable "api_backend_address" {
  description = "后端服务地址，形如 10.0.1.21:8080"
  type        = string
  default     = "10.0.1.21:8080"
}

variable "api_backend_path" {
  description = "后端服务接口路径"
  type        = string
  default     = "/v1/saas"
}

variable "api_tags" {
  description = "API 标签集合"
  type        = list(string)
  default     = ["private", "vpcep"]
}

variable "endpoint_whitelist" {
  description = "允许通过私网终端节点接入的账号 ID 列表；留空表示不额外限制"
  type        = list(string)
  default     = []
}

variable "create_private_zone" {
  description = "是否创建私网域名解析区域，供消费方以固定域名访问"
  type        = bool
  default     = true
}

variable "private_zone_name" {
  description = "私网域名后缀，如 saas.internal"
  type        = string
  default     = "saas.internal"
}
