variable "name_prefix" {
  type    = string
  default = "consumer"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "availability_zone" {
  type    = string
  default = "cn-north-4a"
}

variable "vpc_cidr" {
  type    = string
  default = "192.168.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "192.168.1.0/24"
}
