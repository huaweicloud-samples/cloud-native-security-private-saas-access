
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
  description = "承载后端服务的 VPC ID"
  type        = string
}

variable "ipv4_subnet_id" {
  description = "负载均衡所在子网，取子网资源的 ipv4_subnet_id 字段"
  type        = string
}

variable "availability_zones" {
  description = "可用区列表，需与后端服务所在可用区保持一致"
  type        = list(string)
  default     = ["cn-north-4a", "cn-north-4b"]
}

variable "l4_flavor_name" {
  description = "独享型四层规格名称，用于按名称精确查规格 UUID（TCP/UDP 监听器须用 L4 规格）"
  type        = string
  default     = "L4_flavor.elb.s1.small"
}

variable "listener_protocol" {
  description = "监听器协议，HTTPS 在负载均衡侧终结 TLS，TCP 为四层透传"
  type        = string
  default     = "HTTPS"

  validation {
    condition     = contains(["HTTPS", "TCP"], var.listener_protocol)
    error_message = "监听器协议仅支持 HTTPS 与 TCP。"
  }
}

variable "listener_port" {
  description = "对外服务端口"
  type        = number
  default     = 443
}

variable "backend_protocol" {
  description = "后端服务器组协议"
  type        = string
  default     = "HTTP"
}

variable "backend_port" {
  description = "后端服务实际监听端口"
  type        = number
  default     = 8080
}

variable "backend_addresses" {
  description = "后端服务私网地址列表（IP 型后端），可先留空后补"
  type        = list(string)
  default     = []
}

variable "certificate_id" {
  description = "已有服务器证书 ID；留空且监听器为 HTTPS 时，依据 certificate_content 与 private_key_content 新建"
  type        = string
  default     = ""
}

variable "certificate_content" {
  description = "服务器证书内容（PEM 编码），仅在 certificate_id 留空且监听器为 HTTPS 时必填"
  type        = string
  default     = ""
  sensitive   = true
}

variable "private_key_content" {
  description = "服务器证书私钥（PEM 编码），仅在 certificate_id 留空且监听器为 HTTPS 时必填"
  type        = string
  default     = ""
  sensitive   = true
}

variable "access_cidrs" {
  description = "允许访问的消费方网段列表；留空表示不限制（后端安全组放通全部网段）"
  type        = list(string)
  default     = []
}

variable "health_check" {
  description = "后端健康检查参数"
  type = object({
    protocol    = string
    interval    = number
    timeout     = number
    max_retries = number
    url_path    = string
    port        = number
  })
  default = {
    protocol    = "HTTP"
    interval    = 5
    timeout     = 3
    max_retries = 3
    url_path    = "/health"
    port        = 8080
  }
}

variable "endpoint_service_name" {
  description = "终端节点服务名称，不超过 16 个字符，仅可包含字母、数字、下划线与中划线"
  type        = string
  default     = "privsaas-svc"
}

variable "endpoint_service_approval" {
  description = "消费方建立终端节点时是否需要本端审批"
  type        = bool
  default     = false
}

variable "endpoint_service_permissions" {
  description = "允许连接终端节点服务的账号列表，格式为 iam:domain::<domain_id>，* 表示全部账号；留空表示仅本账号"
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
