# ---------------------------------------------------------------------------
# 终端节点服务
# 后端资源类型为负载均衡，port_id 取负载均衡私网 IP 对应的端口 ID
# ---------------------------------------------------------------------------
resource "huaweicloud_vpcep_service" "service" {
  name        = var.endpoint_service_name
  server_type = "LB"
  vpc_id      = var.vpc_id
  port_id     = huaweicloud_elb_loadbalancer.service.ipv4_port_id
  approval    = var.endpoint_service_approval
  description = "跨 VPC 私网接入服务"

  port_mapping {
    protocol      = "TCP"
    service_port  = var.listener_port
    # 隐式依赖监听器：确保 ELB 监听器先于终端节点服务创建，
    # 避免 VPCEP(LB 类型) 先绑定 LB 443 端口导致监听器创建时端口冲突。
    terminal_port = huaweicloud_elb_listener.service.protocol_port
  }

  permissions = var.endpoint_service_permissions

  tags = var.tags
}
