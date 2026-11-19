# 消费方独立 VPC + 子网 + 安全组，用于验证跨 VPC 的终端节点私连

resource "huaweicloud_vpc" "this" {
  name        = "${var.name_prefix}-vpc"
  cidr        = var.vpc_cidr
  description = "消费方私网（验证跨 VPC 私连）"
  tags        = var.tags
}

resource "huaweicloud_vpc_subnet" "this" {
  name              = "${var.name_prefix}-subnet"
  cidr              = var.subnet_cidr
  gateway_ip        = cidrhost(var.subnet_cidr, 1)
  vpc_id            = huaweicloud_vpc.this.id
  availability_zone = var.availability_zone
  description       = "消费方子网"
  tags              = var.tags
}

resource "huaweicloud_networking_secgroup" "this" {
  name        = "${var.name_prefix}-sg"
  description = "消费方测试安全组"
}

resource "huaweicloud_networking_secgroup_rule" "egress" {
  security_group_id = huaweicloud_networking_secgroup.this.id
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "ingress" {
  security_group_id = huaweicloud_networking_secgroup.this.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = var.subnet_cidr
}
