# 消费方测试虚机：位于消费方 VPC 内，用于从私网侧解析终端节点域名并实测连通。
# 镜像自带 python3，连通性测试用 python 完成，无需联网安装任何组件。

data "huaweicloud_images_image" "ubuntu" {
  os          = "Ubuntu"
  visibility  = "public"
  most_recent = true
  flavor_id   = var.flavor
}

resource "huaweicloud_compute_instance" "this" {
  name              = "${var.name_prefix}-test-vm"
  flavor_id         = var.flavor
  image_id          = data.huaweicloud_images_image.ubuntu.id
  security_group_ids = [var.secgroup_id]
  availability_zone = var.availability_zone
  admin_pass        = var.admin_pass

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
