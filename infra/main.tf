terraform {
  required_version = ">= 1.5.0"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "~> 1.70"
    }
  }
}

provider "huaweicloud" {
  region     = var.region_name
  access_key = var.access_key
  secret_key = var.secret_key
}

# 基线网络：本仓库自包含的 VPC + 单可用区子网（无公网入口）
module "vpc_baseline" {
  source = "./vpc_baseline"

  name_prefix       = var.elb_name_prefix
  tags              = var.tags
  availability_zone = var.elb_availability_zones[0]
}

# 模式一：负载均衡直连（独享型应用型 ELB + 终端节点服务）
module "elb_vpcep_service" {
  count = var.deploy_elb ? 1 : 0

  source = "./elb_vpcep_service"

  name_prefix                  = var.elb_name_prefix
  tags                         = var.tags
  vpc_id                       = module.vpc_baseline.vpc_id
  ipv4_subnet_id               = module.vpc_baseline.subnet_ipv4_id
  availability_zones           = var.elb_availability_zones
  l4_flavor_name               = var.elb_l4_flavor_name
  listener_protocol            = var.elb_listener_protocol
  listener_port                = var.elb_listener_port
  backend_protocol             = var.elb_backend_protocol
  backend_port                 = var.elb_backend_port
  backend_addresses            = concat(var.elb_backend_addresses, var.deploy_elb && var.deploy_backend_vm ? [module.backend_vm[0].private_ip] : [])
  certificate_id               = var.elb_certificate_id
  certificate_content          = var.elb_certificate_content
  private_key_content          = var.elb_private_key_content
  access_cidrs                 = var.elb_access_cidrs
  health_check                 = var.elb_health_check
  endpoint_service_name        = var.elb_endpoint_service_name
  endpoint_service_approval    = var.elb_endpoint_service_approval
  endpoint_service_permissions = var.elb_endpoint_service_permissions
  create_private_zone          = var.elb_create_private_zone
  private_zone_name            = var.elb_private_zone_name
}

# 模式一后端业务虚机：注册为 ELB 成员，提供真实可转发流量（验证端到端连通）
module "backend_vm" {
  count = var.deploy_elb && var.deploy_backend_vm ? 1 : 0

  source = "./backend_vm"

  name_prefix       = var.elb_name_prefix
  tags              = var.tags
  subnet_id         = module.vpc_baseline.subnet_id
  availability_zone = var.elb_availability_zones[0]
  flavor            = var.backend_vm_flavor
  admin_pass        = var.backend_vm_admin_pass
}

# 模式二：API 网关专享版接入（自带私网入口）
module "apig_vpcep_service" {
  count = var.deploy_apig ? 1 : 0

  source = "./apig_vpcep_service"

  name_prefix          = var.apig_name_prefix
  tags                 = var.tags
  vpc_id               = module.vpc_baseline.vpc_id
  subnet_id            = module.vpc_baseline.subnet_id
  availability_zones   = var.apig_availability_zones
  edition              = var.apig_edition
  access_cidrs         = var.apig_access_cidrs
  api_name             = var.apig_api_name
  api_request_protocol = var.apig_api_request_protocol
  api_request_method   = var.apig_api_request_method
  api_request_path     = var.apig_api_request_path
  api_backend_address  = var.apig_api_backend_address
  api_backend_path     = var.apig_api_backend_path
  api_tags             = var.apig_api_tags
  endpoint_whitelist   = var.apig_endpoint_whitelist
  create_private_zone  = var.apig_create_private_zone
  private_zone_name    = var.apig_private_zone_name
}

# 消费方网络：独立 VPC + 子网（验证跨 VPC 私连）
module "consumer_network" {
  count = var.deploy_consumer ? 1 : 0

  source = "./consumer_network"

  name_prefix       = var.consumer_name_prefix
  tags              = var.tags
  availability_zone = var.elb_availability_zones[0]
  vpc_cidr          = var.consumer_vpc_cidr
  subnet_cidr       = var.consumer_subnet_cidr
}

# 消费方终端节点：连接服务端 privsaas-svc，并将私网域名关联到消费方 VPC
module "consumer_vpcep_endpoint" {
  count = var.deploy_consumer ? 1 : 0

  source = "./consumer_vpcep_endpoint"

  name_prefix           = var.consumer_name_prefix
  tags                  = var.tags
  endpoint_service_name = var.consumer_endpoint_service_name
  vpc_id                = module.consumer_network[0].vpc_id
  network_id            = module.consumer_network[0].subnet_id
  enable_dns            = var.consumer_enable_dns
  private_zone_id       = module.elb_vpcep_service[0].private_zone_id
  private_zone_name     = var.consumer_private_zone_name
  record_name           = var.consumer_record_name
  record_ttl            = var.consumer_record_ttl
}

# 模式二消费方终端节点：连接 APIG 专享版自带的网关型终端节点服务
# 网关型服务无法用 huaweicloud_vpcep_services 列表数据源按名称查到，故直接用 service_id 直连
module "consumer_vpcep_endpoint_apig" {
  count = var.deploy_consumer && var.deploy_apig ? 1 : 0

  source = "./consumer_vpcep_endpoint"

  name_prefix           = "${var.consumer_name_prefix}-apig"
  tags                  = var.tags
  endpoint_service_id   = module.apig_vpcep_service[0].endpoint_service_id
  endpoint_service_name = "" # 由 endpoint_service_id 直接定位 APIG 网关型终端节点服务
  vpc_id                = module.consumer_network[0].vpc_id
  network_id            = module.consumer_network[0].subnet_id
  enable_dns            = var.consumer_enable_dns
  # 复用模式一已关联到消费方 VPC 的私网 zone，模块内不再重复关联
  private_zone_id   = ""
  private_zone_name = var.consumer_private_zone_name
  record_name       = "" # 别名由根编排统一注册，避免模块内重复建 recordset
  record_ttl        = var.consumer_record_ttl
}

# 模式二：消费方终端节点连到 APIG 网关型服务后处于 pendingAcceptance，需用 APIG 连接管理资源接受连接，
# 接受后终端节点才分配私网 IP（网关型端点无 private_domain_name，故用 ip_address 注册 A 记录）
resource "huaweicloud_apig_endpoint_connection_management" "apig_conn" {
  count = var.deploy_consumer && var.deploy_apig ? 1 : 0

  instance_id = module.apig_vpcep_service[0].apig_instance_id
  endpoint_id = module.consumer_vpcep_endpoint_apig[0].endpoint_id
  action      = "receive"
}

# 模式二：在已关联到消费方 VPC 的私网 zone 内注册 APIG 易记域名（A 记录指向终端节点私网 IP）
resource "huaweicloud_dns_recordset" "apig_alias" {
  count = var.deploy_consumer && var.deploy_apig ? 1 : 0

  zone_id = module.elb_vpcep_service[0].private_zone_id
  name    = "apig.${var.consumer_private_zone_name}"
  type    = "A"
  records = [module.consumer_vpcep_endpoint_apig[0].endpoint_ip_address]
  ttl     = var.consumer_record_ttl
}

# 消费方测试虚机：从私网侧解析域名并实测连通
module "consumer_test_vm" {
  count = var.deploy_consumer ? 1 : 0

  source = "./consumer_test_vm"

  name_prefix       = var.consumer_name_prefix
  tags              = var.tags
  subnet_id         = module.consumer_network[0].subnet_id
  secgroup_id       = module.consumer_network[0].sg_id
  availability_zone = var.elb_availability_zones[0]
  flavor            = var.consumer_vm_flavor
  admin_pass        = var.consumer_vm_admin_pass
}
