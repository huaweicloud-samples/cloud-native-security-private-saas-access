locals {
  create_alias_record = var.private_zone_id != "" && var.record_name != ""
}

# ---------------------------------------------------------------------------
# 按名称定位服务端终端节点服务
# 已有服务 ID 时跳过查询，直接使用
# ---------------------------------------------------------------------------
data "huaweicloud_vpcep_services" "target" {
  count = var.endpoint_service_id == "" ? 1 : 0

  service_name = var.endpoint_service_name
}

# ---------------------------------------------------------------------------
# 消费方终端节点
# ---------------------------------------------------------------------------
resource "huaweicloud_vpcep_endpoint" "this" {
  service_id = var.endpoint_service_id != "" ? var.endpoint_service_id : data.huaweicloud_vpcep_services.target[0].endpoint_services[0].id
  vpc_id     = var.vpc_id
  network_id = var.network_id
  ip_address = var.ip_address

  enable_dns       = var.enable_dns
  enable_whitelist = var.enable_whitelist
  whitelist        = var.whitelist

  description = "${var.name_prefix} 私网接入终端节点"
  tags        = var.tags
}

# ---------------------------------------------------------------------------
# 将服务端私网域名区域关联到消费方 VPC，并注册易记域名
# ---------------------------------------------------------------------------
resource "huaweicloud_dns_private_zone_associate" "this" {
  count = var.private_zone_id != "" ? 1 : 0

  zone_id   = var.private_zone_id
  router_id = var.vpc_id
}

resource "huaweicloud_dns_recordset" "alias" {
  count = local.create_alias_record ? 1 : 0

  zone_id     = var.private_zone_id
  name        = "${var.record_name}.${var.private_zone_name}"
  type        = "CNAME"
  records     = ["${trimsuffix(huaweicloud_vpcep_endpoint.this.private_domain_name, ".")}."]
  ttl         = var.record_ttl
  description = "指向私网终端节点内网域名"

  depends_on = [huaweicloud_dns_private_zone_associate.this]
}
