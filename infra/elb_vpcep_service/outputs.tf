output "endpoint_service_id" {
  description = "终端节点服务 ID"
  value       = huaweicloud_vpcep_service.service.id
}

output "endpoint_service_name" {
  description = "终端节点服务名称（消费方连接时使用）"
  value       = huaweicloud_vpcep_service.service.service_name
}

output "private_zone_id" {
  description = "私网域名区域 ID，供消费方关联解析"
  value       = huaweicloud_dns_zone.private[0].id
}

output "pool_id" {
  description = "后端服务器组 ID"
  value       = huaweicloud_elb_pool.service.id
}
