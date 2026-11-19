output "vpc_id" {
  description = "消费方 VPC ID"
  value       = huaweicloud_vpc.this.id
}

output "subnet_id" {
  description = "消费方子网资源 id"
  value       = huaweicloud_vpc_subnet.this.id
}

output "subnet_ipv4_id" {
  description = "消费方子网 ipv4_subnet_id"
  value       = huaweicloud_vpc_subnet.this.ipv4_subnet_id
}

output "sg_id" {
  description = "消费方安全组 ID"
  value       = huaweicloud_networking_secgroup.this.id
}

output "sg_name" {
  description = "消费方安全组名称"
  value       = huaweicloud_networking_secgroup.this.name
}
