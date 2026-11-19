# ---------------------------------------------------------------------------
# 基线网络：VPC + 单可用区子网
# 仅承载私网接入的负载均衡与后端服务，不创建任何公网入口（无 EIP / NAT）。
# ---------------------------------------------------------------------------
resource "huaweicloud_vpc" "this" {
  name        = "${var.name_prefix}-vpc"
  cidr        = var.vpc_cidr
  description = "私网 SaaS 接入基线网络"
  tags        = var.tags
}

resource "huaweicloud_vpc_subnet" "this" {
  name              = "${var.name_prefix}-subnet"
  cidr              = var.subnet_cidr
  gateway_ip        = cidrhost(var.subnet_cidr, 1)
  vpc_id            = huaweicloud_vpc.this.id
  availability_zone = var.availability_zone
  description       = "私网接入子网"
  tags              = var.tags
}
