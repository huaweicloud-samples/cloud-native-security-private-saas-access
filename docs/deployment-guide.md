# 私网 SaaS 接入部署指导书

## 1. 部署概览

本仓库提供三套独立的 Terraform 配置，可按需单独部署：

| 目录 | 作用 | 部署方 |
|---|---|---|
| `infra/elb_vpcep_service` | 模式一服务端：负载均衡 + 终端节点服务 | 服务方 |
| `infra/apig_vpcep_service` | 模式二服务端：API 网关专享版 + 私网入口 | 服务方 |
| `infra/consumer_vpcep_endpoint` | 消费方：终端节点 + 可选私网域名记录 | 消费方 |

> 模式一与模式二二选一，消费方配置两种模式通用。

## 2. 环境准备

### 2.1 配置访问密钥

请在华为云『我的凭证』页面获取 Access Key（AK/SK），经环境变量提供给 Terraform：

```bash
export TF_VAR_access_key="<AK>"
export TF_VAR_secret_key="<SK>"
```

> 不要将凭据写入 `terraform.tfvars` 或任何被版本管理的文件。

### 2.2 准备网络信息

| 信息 | 获取方式 | 用途 |
|---|---|---|
| 服务方 VPC ID | 控制台 VPC 列表 | `vpc_id` |
| 子网 `ipv4_subnet_id` | `terraform output` 或控制台子网详情 | `ipv4_subnet_id`（模式一） |
| 子网 `id` | 控制台子网详情 | `subnet_id`（模式二） |
| 子网 `subnet_id` | 控制台子网详情 | `network_id`（消费方） |
| 后端服务私网地址 | 业务服务部署信息 | `backend_addresses` |

> **注意**：子网资源同时暴露 `id`、`subnet_id`、`ipv4_subnet_id` 三个不同 UUID，不可混用；本指导书已在变量说明中标注各自取值。

### 2.3 检查工具版本

```bash
terraform version
```

**预期输出**：`Terraform v1.5.0` 或更高版本。

---

## 3. 模式一部署（负载均衡直连）

### 3.1 配置变量

```bash
cd <本仓库根目录>/infra/elb_vpcep_service
cp terraform.tfvars.example terraform.tfvars
```

按实际环境编辑 `terraform.tfvars`，最小必填项：

```hcl
region_name        = "cn-north-4"
vpc_id             = "<服务方 VPC ID>"
ipv4_subnet_id     = "<子网 ipv4_subnet_id>"
availability_zones = ["cn-north-4a", "cn-north-4b"]
backend_addresses  = ["10.0.1.21", "10.0.1.22"]
```

### 3.2 初始化与校验

```bash
terraform init
terraform fmt -check
terraform validate
```

**预期输出**：`Success! The configuration is valid.`

### 3.3 部署

```bash
terraform plan
terraform apply -auto-approve
```

**预期输出**：`Apply complete! Resources: N added, 0 changed, 0 destroyed.`

### 3.4 记录输出

```bash
terraform output
```

**预期输出**：

```
endpoint_service_name = "cn-north-4.privsaas-svc.<service-id>"
endpoint_service_id   = "<service-id>"
private_zone_id       = "<zone-id>"
service_address       = "10.0.1.100"
backend_security_group_id = "<sg-id>"
```

> `backend_security_group_id` 需挂到后端服务实例上，放通后端端口与健康检查端口。

### 3.5 HTTPS 证书配置

两种方式二选一：

```hcl
# 方式一：使用已有证书 ID
certificate_id = "<已有 ELB 证书 ID>"

# 方式二：由模块依据证书内容创建
certificate_id       = ""
certificate_content  = file("server.crt")
private_key_content  = file("server.key")
```

若改为四层透传，则不需要证书：

```hcl
listener_protocol = "TCP"
backend_protocol  = "HTTPS"
```

---

## 4. 模式二部署（API 网关专享版）

### 4.1 配置变量

```bash
cd <本仓库根目录>/infra/apig_vpcep_service
cp terraform.tfvars.example terraform.tfvars
```

最小必填项：

```hcl
region_name = "cn-north-4"
vpc_id      = "<服务方 VPC ID>"
subnet_id   = "<子网 id>"
edition     = "BASIC"

api_backend_address = "10.0.1.21:8080"
```

### 4.2 初始化与部署

```bash
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

**预期输出**：`Apply complete! Resources: N added, 0 changed, 0 destroyed.`

> API 网关专享版实例创建耗时较长，通常在 20-30 分钟，请耐心等待。

### 4.3 记录输出

```bash
terraform output
```

**预期输出**：

```
endpoint_service_name    = "apig"
endpoint_service_address = "cn-north-4.apig.<instance-id>"
vpc_ingress_address      = "10.0.1.50"
api_id                   = "<api-id>"
private_zone_id          = "<zone-id>"
```

---

## 5. 消费方部署

### 5.1 配置变量

```bash
cd <本仓库根目录>/infra/consumer_vpcep_endpoint
cp terraform.tfvars.example terraform.tfvars
```

最小必填项：

```hcl
region_name  = "cn-north-4"

# 二选一，优先使用服务方输出的 endpoint_service_id
endpoint_service_id   = "<service-id>"
endpoint_service_name = ""

vpc_id     = "<消费方 VPC ID>"
network_id = "<消费方子网 subnet_id>"
```

> `network_id` 取子网资源的 `subnet_id` 字段（网络 ID），不是 VPC 层子网 ID。

### 5.2 部署

```bash
terraform init
terraform validate
terraform apply -auto-approve
```

**预期输出**：`Apply complete! Resources: N added, 0 changed, 0 destroyed.`

### 5.3 若服务端开启了连接审批

消费方创建终端节点后状态为 `pendingAcceptance`，服务方需执行：

1. 打开控制台「VPC 终端节点 → 终端节点服务」
2. 进入对应服务的「连接管理」
3. 对目标连接执行「接受」

接受后消费方再次查看状态应为 `accepted`。

### 5.4 配置私网域名（可选）

```hcl
private_zone_id   = "<服务方输出的 zone-id>"
private_zone_name = "saas.internal"
record_name       = "saas"
record_ttl        = 300
```

模块会自动完成两件事：把私网区域关联到消费方 VPC、注册 `<record_name>.<private_zone_name>` 的 CNAME 记录指向终端节点内网域名。

---

## 6. 验证

### 6.1 静态校验（无需部署）

```bash
cd <本仓库根目录>/infra/elb_vpcep_service && terraform validate
cd <本仓库根目录>/infra/apig_vpcep_service && terraform validate
cd <本仓库根目录>/infra/consumer_vpcep_endpoint && terraform validate
```

**预期输出**：三个目录均输出 `Success! The configuration is valid.`

### 6.2 连接状态

```bash
cd <本仓库根目录>/infra/consumer_vpcep_endpoint
terraform output endpoint_status
```

**预期输出**：`accepted`

### 6.3 业务连通性

```bash
# 在消费方 VPC 内的云服务器上执行
curl -vk https://<service_access_address>/health
```

**预期结果**：返回 HTTP 200，TLS 握手成功。

---

## 7. 释放资源

```bash
cd <本仓库根目录>/infra/consumer_vpcep_endpoint && terraform destroy -auto-approve
cd <本仓库根目录>/infra/elb_vpcep_service && terraform destroy -auto-approve
```

**预期输出**：`Destroy complete! Resources: N destroyed.`

> 若销毁中断，重新执行 `terraform destroy`；华为云要求先删后端服务器组与监听器，再删负载均衡。

---

## 8. 常见问题

| 现象 | 原因 | 处理 |
|---|---|---|
| 规格 UUID 类型报错 | `l7_flavor_id` 填了规格名称 | 保持 `l7_flavor_name` 为规格名，由模块解析 UUID |
| 终端节点找不到服务 | 区域不一致或名称填错 | 确认两端 `region_name` 一致，名称取服务方输出值 |
| 一直处于待接受 | 服务端开启了连接审批 | 在服务方控制台接受连接 |
| 域名解析失败 | 私网区域未关联消费方 VPC | 填入 `private_zone_id` 后重新应用 |
| 销毁时监听器冲突 | 后端服务器组仍挂载在监听器上 | 重新执行 `terraform destroy` |
