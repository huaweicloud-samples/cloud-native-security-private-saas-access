locals {
  apig_source_cidrs = length(var.access_cidrs) > 0 ? var.access_cidrs : ["0.0.0.0/0"]
}

# ---------------------------------------------------------------------------
# API 网关实例安全组
# ---------------------------------------------------------------------------
resource "huaweicloud_networking_secgroup" "apig" {
  name        = "${var.name_prefix}-apig"
  description = "API 网关专享版实例安全组"
}

resource "huaweicloud_networking_secgroup_rule" "apig_ingress_https" {
  for_each = toset(local.apig_source_cidrs)

  security_group_id = huaweicloud_networking_secgroup.apig.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = each.value
  description       = "放通私网终端节点对 443 端口的访问"
}

# ---------------------------------------------------------------------------
# API 网关专享版实例
# 实例自带私网接入入口，消费方在其 VPC 内创建终端节点即可跨 VPC 私网调用
# ---------------------------------------------------------------------------
resource "huaweicloud_apig_instance" "this" {
  name              = "${var.name_prefix}-apig"
  description       = "承载私网接入的 API 网关专享版实例"
  edition           = var.edition
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  security_group_id = huaweicloud_networking_secgroup.apig.id
  available_zones   = var.availability_zones
  tags              = var.tags
}

resource "huaweicloud_apig_endpoint_whitelist" "this" {
  count = length(var.endpoint_whitelist) > 0 ? 1 : 0

  instance_id = huaweicloud_apig_instance.this.id
  whitelists  = var.endpoint_whitelist
}

# ---------------------------------------------------------------------------
# API 分组、环境与 API
# ---------------------------------------------------------------------------
# APIG 专享版实例创建时会自动生成名为 DEFAULT 的默认分组，
# 只有 DEFAULT 分组中的 API 才能通过 EIP 或私网 IP（含 VPCEP 终端节点）访问。
# 自定义分组仅支持公网域名访问，在私网 VPCEP 场景下会报 APIG.2046。
# 因此使用数据源查询默认分组，不再新建自定义分组。
data "huaweicloud_apig_groups" "default" {
  instance_id = huaweicloud_apig_instance.this.id
  name        = "DEFAULT"
}

# APIG 专享版实例创建时会自动生成名为 RELEASE 的默认环境（id 固定为 "DEFAULT_ENVIRONMENT_RELEASE_ID"）。
# 通过 VPCEP 私网访问时，APIG 只识别默认 RELEASE 环境下的 API；自建环境（如 PROD）下的 API
# 在私网访问路径中怎么都报 APIG.0101。因此直接复用默认 RELEASE，不写 huaweicloud_apig_environment 资源。

resource "huaweicloud_apig_api" "this" {
  instance_id             = huaweicloud_apig_instance.this.id
  group_id                = data.huaweicloud_apig_groups.default.groups[0].id
  name                    = var.api_name
  type                    = "Private"
  request_protocol        = var.api_request_protocol
  request_method          = var.api_request_method
  request_path            = var.api_request_path
  # matching 字段：provider 1.96.0 对 exact/EXACT/prefix 均判为 invalid match mode，且 APIG REST API 对此字段
  # 有独立校验。先省略该字段，由 APIG 后端默认处理（默认 exact 匹配），避免 buildAPIOpts 校验失败。
  # matching              = "EXACT"
  security_authentication = "NONE"
  description             = "经私网终端节点暴露的 API"
  tags                    = var.api_tags

  web {
    path             = var.api_backend_path
    backend_address  = var.api_backend_address
    request_method   = var.api_request_method
    request_protocol = "HTTP"
    timeout          = 5000
    retry_count      = 0
  }
}

resource "huaweicloud_apig_api_publishment" "this" {
  instance_id = huaweicloud_apig_instance.this.id
  api_id      = huaweicloud_apig_api.this.id
  # 私网 VPCEP 访问时 APIG 只识别默认 RELEASE 环境下的 API
  env_id      = "DEFAULT_ENVIRONMENT_RELEASE_ID"
  description = "发布到默认 RELEASE 环境"
}
