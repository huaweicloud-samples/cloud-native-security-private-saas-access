# 后端业务虚机：在 provider 私网子网内起一台 Ubuntu ECS，
# 监听 8080 提供 HTTP 健康检查（/health）与业务响应，供 ELB 转发并验证真实流量。

data "huaweicloud_images_image" "ubuntu" {
  os          = "Ubuntu"
  visibility  = "public"
  most_recent = true
  flavor_id   = var.flavor
}

resource "huaweicloud_networking_secgroup" "this" {
  name        = "${var.name_prefix}-backend-sg"
  description = "后端业务虚机安全组（放通 8080）"
}

resource "huaweicloud_networking_secgroup_rule" "ingress" {
  security_group_id = huaweicloud_networking_secgroup.this.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "egress" {
  security_group_id = huaweicloud_networking_secgroup.this.id
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_compute_instance" "this" {
  name              = "${var.name_prefix}-backend-vm"
  flavor_id         = var.flavor
  image_id          = data.huaweicloud_images_image.ubuntu.id
  security_group_ids = [huaweicloud_networking_secgroup.this.id]
  availability_zone = var.availability_zone
  admin_pass        = var.admin_pass

  user_data = <<-EOF
    #!/bin/bash
    mkdir -p /opt/saas
    echo "private-saas backend OK" > /opt/saas/health
    cd /opt/saas
    nohup python3 -m http.server 8080 --bind 0.0.0.0 >/tmp/saas.log 2>&1 &
  EOF

  network {
    uuid = var.subnet_id
  }

  tags = var.tags

  # admin_pass 是创建期一次性字段，且为敏感值：后续 apply 若 var.admin_pass 未传（null），
  # terraform 会尝试把密码重置为空而被 ECS API 拒绝（Ecs.0011）。忽略该字段的变更差异，
  # 既不触碰线上密码，又保证首次创建时仍按传入值设置密码（ignore_changes 仅作用于更新期）。
  lifecycle {
    ignore_changes = [admin_pass]
  }
}
