# 根模块变量：统一编排三种独立可部署模式
# 模式一 elb_vpcep_service：负载均衡直连（独享型应用型 ELB + 终端节点服务）
# 模式二 apig_vpcep_service：API 网关专享版接入（自带私网入口）
# 消费方 consumer_vpcep_endpoint：在消费方 VPC 内创建终端节点
#
# 三个子模块均为自包含单元，可进入各自目录独立 terraform apply；
# 本根模块提供「一键编排 / 选择性部署」的便捷入口。

variable "access_key" {
  description = "账号 Access Key，建议通过环境变量 TF_VAR_access_key 提供，不要写入任何文件"
  type        = string
  default     = null
  sensitive   = true
}

variable "secret_key" {
  description = "账号 Secret Key，建议通过环境变量 TF_VAR_secret_key 提供，不要写入任何文件"
  type        = string
  default     = null
  sensitive   = true
}

variable "region_name" {
  description = "部署区域，服务端与消费端需保持一致"
  type        = string
  default     = "cn-north-4"
}

variable "tags" {
  description = "统一附加到资源的标签"
  type        = map(string)
  default     = {}
}

# ---- 部署开关：按需启用对应模式 ----
variable "deploy_elb" {
  description = "是否部署模式一（负载均衡直连）"
  type        = bool
  default     = true
}

variable "deploy_apig" {
  description = "是否部署模式二（API 网关专享版）"
  type        = bool
  default     = false
}

variable "deploy_consumer" {
  description = "是否在消费方 VPC 创建终端节点（需先部署服务端并填入 endpoint_service_id / name）"
  type        = bool
  default     = false
}

# ================= 模式一：elb_vpcep_service =================
variable "elb_name_prefix" {
  type    = string
  default = "privsaas"
}
variable "elb_availability_zones" {
  type    = list(string)
  default = ["cn-north-4a"]
}
variable "elb_l4_flavor_name" {
  type    = string
  default = "L4_flavor.elb.s1.small"
}
variable "elb_listener_protocol" {
  type    = string
  default = "HTTPS"
  validation {
    condition     = contains(["HTTPS", "TCP"], var.elb_listener_protocol)
    error_message = "监听器协议仅支持 HTTPS 与 TCP。"
  }
}
variable "elb_listener_port" {
  type    = number
  default = 443
}
variable "elb_backend_protocol" {
  type    = string
  default = "HTTP"
}
variable "elb_backend_port" {
  type    = number
  default = 8080
}
variable "elb_backend_addresses" {
  type    = list(string)
  default = []
}
variable "elb_certificate_id" {
  type    = string
  default = ""
}
variable "elb_certificate_content" {
  type      = string
  default   = ""
  sensitive = true
}
variable "elb_private_key_content" {
  type      = string
  default   = ""
  sensitive = true
}
variable "elb_access_cidrs" {
  type    = list(string)
  default = []
}
variable "elb_health_check" {
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
variable "elb_endpoint_service_name" {
  type    = string
  default = "privsaas-svc"
}
variable "elb_endpoint_service_approval" {
  type    = bool
  default = false
}
variable "elb_endpoint_service_permissions" {
  type    = list(string)
  default = []
}
variable "elb_create_private_zone" {
  type    = bool
  default = true
}
variable "elb_private_zone_name" {
  type    = string
  default = "saas.internal"
}

# ================= 模式二：apig_vpcep_service =================
variable "apig_name_prefix" {
  type    = string
  default = "privsaas"
}
variable "apig_availability_zones" {
  type    = list(string)
  default = ["cn-north-4a"]
}
variable "apig_edition" {
  type    = string
  default = "BASIC"
  validation {
    condition = contains(
      ["BASIC", "PROFESSIONAL", "ENTERPRISE", "PLATINUM",
      "BASIC_IPV6", "PROFESSIONAL_IPV6", "ENTERPRISE_IPV6", "PLATINUM_IPV6"],
      var.apig_edition
    )
    error_message = "规格仅支持专享版系列：BASIC / PROFESSIONAL / ENTERPRISE / PLATINUM（及对应 IPV6 变体）。"
  }
}
variable "apig_access_cidrs" {
  type    = list(string)
  default = []
}
variable "apig_api_name" {
  type    = string
  default = "private-echo"
}
variable "apig_api_request_protocol" {
  type    = string
  default = "HTTPS"
}
variable "apig_api_request_method" {
  type    = string
  default = "ANY"
}
variable "apig_api_request_path" {
  type    = string
  default = "/v1/saas"
}
variable "apig_api_backend_address" {
  type    = string
  default = "10.0.1.21:8080"
}
variable "apig_api_backend_path" {
  type    = string
  default = "/v1/saas"
}
variable "apig_api_tags" {
  type    = list(string)
  default = ["private", "vpcep"]
}
variable "apig_endpoint_whitelist" {
  type    = list(string)
  default = []
}
variable "apig_create_private_zone" {
  type    = bool
  default = true
}
variable "apig_private_zone_name" {
  type    = string
  default = "saas.internal"
}

# ================= 消费方：consumer_vpcep_endpoint =================
variable "consumer_name_prefix" {
  type    = string
  default = "consumer"
}
variable "consumer_endpoint_service_id" {
  description = "服务端终端节点服务 ID；留空时按 endpoint_service_name 查找"
  type        = string
  default     = ""
}
variable "consumer_endpoint_service_name" {
  type    = string
  default = ""
}
variable "consumer_vpc_id" {
  description = "消费方 VPC ID"
  type        = string
}
variable "consumer_network_id" {
  description = "消费方子网的网络 ID，取子网资源的 subnet_id 字段"
  type        = string
}
variable "consumer_ip_address" {
  type    = string
  default = null
}
variable "consumer_enable_dns" {
  type    = bool
  default = true
}
variable "consumer_enable_whitelist" {
  type    = bool
  default = false
}
variable "consumer_whitelist" {
  type    = list(string)
  default = []
}
variable "consumer_private_zone_id" {
  type    = string
  default = ""
}
variable "consumer_private_zone_name" {
  type    = string
  default = "saas.internal"
}
variable "consumer_record_name" {
  type    = string
  default = "saas"
}
variable "consumer_record_ttl" {
  type    = number
  default = 300
}

# ================= 端到端验证补充 =================
variable "deploy_backend_vm" {
  description = "是否部署模式一后端业务虚机（注册为 ELB 成员，验证真实流量转发）"
  type        = bool
  default     = true
}

variable "backend_vm_flavor" {
  type    = string
  default = "s6.large.2"
}

variable "backend_vm_admin_pass" {
  description = "后端虚机登录密码，建议通过 TF_VAR_backend_vm_admin_pass 环境变量提供，不要写入文件"
  type        = string
  default     = ""
  sensitive   = true
}

variable "consumer_vpc_cidr" {
  description = "消费方 VPC CIDR"
  type        = string
  default     = "192.168.0.0/16"
}

variable "consumer_subnet_cidr" {
  description = "消费方子网 CIDR"
  type        = string
  default     = "192.168.1.0/24"
}

variable "consumer_vm_flavor" {
  type    = string
  default = "s6.large.2"
}

variable "consumer_vm_admin_pass" {
  description = "消费方测试虚机登录密码，建议通过 TF_VAR_consumer_vm_admin_pass 环境变量提供"
  type        = string
  default     = ""
  sensitive   = true
}
