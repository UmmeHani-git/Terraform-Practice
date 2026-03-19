# VPC
variable "vpc_cidr" {}
variable "private_subnet_1_cidr" {}
variable "private_subnet_2_cidr" {}
variable "az1" {}
variable "az2" {}
variable "allowed_cidr" {
  type = list(string)
}

# RDS
variable "db_identifier" {}
variable "allocated_storage" {}
variable "engine_version" {}
variable "instance_class" {}
variable "db_name" {}
variable "username" {}

variable "password" {
  sensitive = true
}