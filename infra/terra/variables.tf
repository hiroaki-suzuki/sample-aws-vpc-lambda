# AWSアクセスキー
variable "aws_access_key" {}
# AWSシークレットキー
variable "aws_secret_key" {}
# AWSアカウントID
variable "aws_account_id" {}
# AWSリージョン
variable "aws_region" {}
# AZ 1
variable "availability_zone_1" {}
# AZ 2
variable "availability_zone_2" {}
# リソース接頭辞
variable "name_prefix" {}
# VPC CIDR
variable "vpc_cidr" {}
# Public Subnet a
variable "public_subnet_1_cidr" {}
# Public Subnet c
variable "public_subnet_2_cidr" {}
# Private Subnet a for App CIDR
variable "private_subnet_app_1_cidr" {}
# Private Subnet c for App CIDR
variable "private_subnet_app_2_cidr" {}
# Private Subnet a for DB CIDR
variable "private_subnet_db_1_cidr" {}
# Private Subnet c for DB CIDR
variable "private_subnet_db_2_cidr" {}
# DBユーザー
variable "db_username" {}
# DBパスワード
variable "db_password" {}
# RDS Proxy IAM Policy KMS ARN
variable "rds_proxy_iam_policy_kms_arn" {}