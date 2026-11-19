data "huaweicloud_elb_flavors" "l4" {
  type = "L4"
}

locals {
  # 规格字段只接受 UUID，必须按规格名称精确取值，不能直接取列表首项
  # 监听器为 TCP（四层透传），故负载均衡必须使用 L4 规格；
  # L7 规格的 ELB 仅支持 HTTP/HTTPS 监听器，建 TCP 监听器会触发 ELB.8907。
  l4_flavor_id = try(
    [for f in data.huaweicloud_elb_flavors.l4.flavors : f.id if f.name == var.l4_flavor_name][0],
    data.huaweicloud_elb_flavors.l4.flavors[0].id
  )

  tls_enabled = var.listener_protocol == "HTTPS"

  server_certificate_id = var.certificate_id != "" ? var.certificate_id : (
    local.tls_enabled ? try(huaweicloud_elb_certificate.server[0].id, "") : ""
  )

  backend_source_cidrs = length(var.access_cidrs) > 0 ? var.access_cidrs : ["0.0.0.0/0"]

  backend_ports = distinct([var.backend_port, var.health_check.port])
}
