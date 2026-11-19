output "id" {
  description = "后端业务虚机 ID"
  value       = huaweicloud_compute_instance.this.id
}

output "private_ip" {
  description = "后端业务虚机私网 IP，供 ELB 注册为成员"
  value       = huaweicloud_compute_instance.this.access_ip_v4
}
