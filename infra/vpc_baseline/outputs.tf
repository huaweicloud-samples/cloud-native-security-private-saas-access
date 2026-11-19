output "vpc_id" {
  description = "基线 VPC ID"
  value       = huaweicloud_vpc.this.id
}

# 独享型 ELB 使用子网资源的 ipv4_subnet_id 字段
output "subnet_ipv4_id" {
  description = "子网 ipv4_subnet_id，供独享型 ELB 使用"
  value       = huaweicloud_vpc_subnet.this.ipv4_subnet_id
}

# 子网资源 id，供 API 网关等使用
output "subnet_id" {
  description = "子网资源 id，供 API 网关专享版等使用"
  value       = huaweicloud_vpc_subnet.this.id
}
