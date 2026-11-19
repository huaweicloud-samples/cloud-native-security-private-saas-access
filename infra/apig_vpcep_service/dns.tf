# ---------------------------------------------------------------------------
# 私网域名解析区域
# 消费方在本区域下添加 CNAME 记录，即可用固定域名访问终端节点
# ---------------------------------------------------------------------------
resource "huaweicloud_dns_zone" "private" {
  count = var.create_private_zone ? 1 : 0

  name        = var.private_zone_name
  description = "私网访问域名解析区域"
  zone_type   = "private"
  ttl         = 300

  dynamic "router" {
    for_each = toset([var.vpc_id])

    content {
      router_id = router.value
    }
  }

  tags = var.tags
}
