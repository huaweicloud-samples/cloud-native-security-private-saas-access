# ---------------------------------------------------------------------------
# 后端服务安全组
# 独享型负载均衡不绑定安全组，该安全组供后端服务实例引用；
# 前端访问控制由监听器的 IP 地址组（access_cidrs）承担。
# ---------------------------------------------------------------------------
resource "huaweicloud_networking_secgroup" "backend" {
  name        = "${var.name_prefix}-backend"
  description = "后端服务安全组"
}

resource "huaweicloud_networking_secgroup_rule" "backend_ingress" {
  for_each = toset([for p in local.backend_ports : tostring(p)])

  security_group_id = huaweicloud_networking_secgroup.backend.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = tonumber(each.value)
  port_range_max    = tonumber(each.value)
  remote_ip_prefix  = local.backend_source_cidrs[0]
  description       = "放通后端服务 ${each.value} 端口"
}

# ---------------------------------------------------------------------------
# 监听器 IP 地址组：消费方网段白名单
# ---------------------------------------------------------------------------
resource "huaweicloud_elb_ipgroup" "service" {
  count = length(var.access_cidrs) > 0 ? 1 : 0

  name        = "${var.name_prefix}-allow"
  description = "允许访问服务的消费方网段"

  dynamic "ip_list" {
    for_each = toset(var.access_cidrs)

    content {
      ip          = ip_list.value
      description = "消费方网段"
    }
  }
}

# ---------------------------------------------------------------------------
# 服务器证书：HTTPS 监听时终结 TLS
# ---------------------------------------------------------------------------
resource "huaweicloud_elb_certificate" "server" {
  count = var.certificate_id == "" && local.tls_enabled ? 1 : 0

  name        = "${var.name_prefix}-server"
  description = "服务端证书"
  certificate = var.certificate_content
  private_key = var.private_key_content
}

# ---------------------------------------------------------------------------
# 独享型负载均衡
# ---------------------------------------------------------------------------
resource "huaweicloud_elb_loadbalancer" "service" {
  name              = "${var.name_prefix}-elb"
  description       = "承载私网访问的独享型负载均衡"
  vpc_id            = var.vpc_id
  ipv4_subnet_id    = var.ipv4_subnet_id
  availability_zone = var.availability_zones
  l4_flavor_id      = local.l4_flavor_id
  cross_vpc_backend = true

  deletion_protection_enable = false
  tags                       = var.tags
}

# 后端服务器组只关联负载均衡，不关联监听器，避免与监听器形成循环依赖
resource "huaweicloud_elb_pool" "service" {
  name            = "${var.name_prefix}-pool"
  description     = "后端服务池"
  protocol        = var.backend_protocol
  lb_method       = "ROUND_ROBIN"
  loadbalancer_id = huaweicloud_elb_loadbalancer.service.id
}

resource "huaweicloud_elb_member" "service" {
  # 以静态下标为 key，避免后端 IP（apply 时才确定）导致 for_each 集合未知而无法 plan
  for_each = { for i, a in var.backend_addresses : tostring(i) => a }

  pool_id       = huaweicloud_elb_pool.service.id
  address       = each.value
  protocol_port = var.backend_port
  name          = "${var.name_prefix}-member-${each.key}"
}

resource "huaweicloud_elb_monitor" "service" {
  pool_id     = huaweicloud_elb_pool.service.id
  protocol    = var.health_check.protocol
  interval    = var.health_check.interval
  timeout     = var.health_check.timeout
  max_retries = var.health_check.max_retries
  port        = var.health_check.port
  url_path    = var.health_check.protocol == "HTTP" ? var.health_check.url_path : null
  name        = "${var.name_prefix}-hc"
}

resource "huaweicloud_elb_listener" "service" {
  name               = "${var.name_prefix}-listener"
  description        = "对外服务监听器"
  loadbalancer_id    = huaweicloud_elb_loadbalancer.service.id
  protocol           = var.listener_protocol
  protocol_port      = var.listener_port
  default_pool_id    = huaweicloud_elb_pool.service.id
  server_certificate = local.tls_enabled ? (local.server_certificate_id != "" ? local.server_certificate_id : null) : null
  access_policy      = length(var.access_cidrs) > 0 ? "white" : null
  ip_group           = length(var.access_cidrs) > 0 ? huaweicloud_elb_ipgroup.service[0].id : null
}
