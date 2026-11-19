output "id" {
  description = "消费方测试虚机 ID"
  value       = huaweicloud_compute_instance.this.id
}

output "private_ip" {
  description = "消费方测试虚机私网 IP"
  value       = huaweicloud_compute_instance.this.access_ip_v4
}
