output "apig_instance_id" {
  description = "API 网关专享版实例 ID"
  value       = huaweicloud_apig_instance.this.id
}

output "endpoint_service_name" {
  description = "实例自带终端节点服务全名（cn-north-4.apig.<uuid>），消费方按此名称查找 VPCEP 服务"
  value       = huaweicloud_apig_instance.this.vpcep_service_address
}

output "endpoint_service_address" {
  description = "实例自带终端节点服务全名（cn-north-4.apig.<uuid>），消费方创建终端节点时按此名称查找服务"
  value       = huaweicloud_apig_instance.this.vpcep_service_address
}

# APIG 专享版（BASIC 规格）实例自带的终端节点服务为 interface 型，不被 huaweicloud_vpcep_services
# 列表数据源返回（该数据源也未必返回 APIG 自带的 interface 型服务，实测 BASIC 规格查不到）。
# 消费方需直接用 service_id 直连。service_id 即 vpcep_service_address 末段 UUID。
output "endpoint_service_id" {
  description = "APIG 实例自带终端节点服务 ID（UUID），消费方据此直接创建终端节点"
  value       = element(split(".", huaweicloud_apig_instance.this.vpcep_service_address), length(split(".", huaweicloud_apig_instance.this.vpcep_service_address)) - 1)
}

output "vpc_ingress_address" {
  description = "实例私网入口地址"
  value       = huaweicloud_apig_instance.this.vpc_ingress_address
}

output "api_group_id" {
  description = "API 分组 ID（DEFAULT 分组）"
  value       = data.huaweicloud_apig_groups.default.groups[0].id
}

output "api_id" {
  description = "API ID"
  value       = huaweicloud_apig_api.this.id
}

output "security_group_id" {
  description = "API 网关实例安全组 ID"
  value       = huaweicloud_networking_secgroup.apig.id
}

output "private_zone_id" {
  description = "私网域名解析区域 ID，消费方模块需要引用"
  value       = try(huaweicloud_dns_zone.private[0].id, null)
}

output "private_zone_name" {
  description = "私网域名后缀"
  value       = var.create_private_zone ? var.private_zone_name : null
}
