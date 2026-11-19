output "endpoint_id" {
  description = "终端节点 ID"
  value       = huaweicloud_vpcep_endpoint.this.id
}

output "endpoint_ip_address" {
  description = "终端节点私网地址，供消费方应用直连"
  value       = huaweicloud_vpcep_endpoint.this.ip_address
}

output "endpoint_private_domain_name" {
  description = "终端节点内网域名，开启 enable_dns 后由平台自动生成"
  value       = huaweicloud_vpcep_endpoint.this.private_domain_name
}

output "endpoint_status" {
  description = "终端节点连接状态，accepted 表示已建立连接"
  value       = huaweicloud_vpcep_endpoint.this.status
}

output "alias_record_fqdn" {
  description = "注册的易记域名，未配置域名区域时为 null"
  value       = local.create_alias_record ? "${var.record_name}.${var.private_zone_name}" : null
}

output "service_access_address" {
  description = "建议使用的访问入口，优先取易记域名，其次取终端节点私网地址"
  value = local.create_alias_record ? "${var.record_name}.${var.private_zone_name}" : (
    huaweicloud_vpcep_endpoint.this.private_domain_name != "" ? huaweicloud_vpcep_endpoint.this.private_domain_name : huaweicloud_vpcep_endpoint.this.ip_address
  )
}
