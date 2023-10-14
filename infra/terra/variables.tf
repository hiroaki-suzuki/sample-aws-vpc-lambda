# AWSアクセスキー
variable "aws_access_key" {}
# AWSシークレットキー
variable "aws_secret_key" {}
# AWSアカウントID
variable "aws_account_id" {}
# リソース接頭辞
variable "name_prefix" {}
# VPC CIDR
variable "vpc_cidr" {}
# Public Subnet a
variable "public_subnet_a_cidr" {}
# Public Subnet c
variable "public_subnet_c_cidr" {}
# Private Subnet a for App CIDR
variable "private_subnet_app_a_cidr" {}
# Private Subnet c for App CIDR
variable "private_subnet_app_c_cidr" {}
# Private Subnet a for DB CIDR
variable "private_subnet_db_a_cidr" {}
# Private Subnet c for DB CIDR
variable "private_subnet_db_c_cidr" {}
