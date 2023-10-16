terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.21.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

##################################
# VPC
##################################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

##################################
# Subnet
##################################
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_1_cidr
  availability_zone = var.availability_zone_1

  tags = {
    Name = "${var.name_prefix}-public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_2_cidr
  availability_zone = var.availability_zone_2

  tags = {
    Name = "${var.name_prefix}-public-subnet-2"
  }
}

resource "aws_subnet" "private_app_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_app_1_cidr
  availability_zone = var.availability_zone_1

  tags = {
    Name = "${var.name_prefix}-private-subnet-app-1"
  }
}

resource "aws_subnet" "private_app_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_app_2_cidr
  availability_zone = var.availability_zone_2

  tags = {
    Name = "${var.name_prefix}-private-subnet-app-2"
  }
}

resource "aws_subnet" "private_db_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_db_1_cidr
  availability_zone = var.availability_zone_1

  tags = {
    Name = "${var.name_prefix}-private-subnet-db-1"
  }
}

resource "aws_subnet" "private_db_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_db_2_cidr
  availability_zone = var.availability_zone_2

  tags = {
    Name = "${var.name_prefix}-private-subnet-db-2"
  }
}

##################################
# Internet Gateway
##################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

##################################
# NAT Gateway
##################################
resource "aws_eip" "ngw_1" {
  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}-ngw-eip-1"
  }
}

resource "aws_nat_gateway" "ngw_1" {
  allocation_id = aws_eip.ngw_1.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.name_prefix}-ngw-1"
  }
}

##################################
# Route Table
##################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.name_prefix}-public-rtb"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw_1.id
  }

  tags = {
    Name = "${var.name_prefix}-private-app-rtb"
  }
}

resource "aws_route_table_association" "private_app_1" {
  subnet_id      = aws_subnet.private_app_1.id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_route_table_association" "private_app_2" {
  subnet_id      = aws_subnet.private_app_2.id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-private-db-rtb"
  }
}

resource "aws_route_table_association" "private_db_1" {
  subnet_id      = aws_subnet.private_db_1.id
  route_table_id = aws_route_table.private_db.id
}

resource "aws_route_table_association" "private_db_2" {
  subnet_id      = aws_subnet.private_db_2.id
  route_table_id = aws_route_table.private_db.id
}

##################################
# Security Group
##################################
# VPC Endpoint用のセキュリティグループ
resource "aws_security_group" "vpc_endpoint" {
  name        = "${var.name_prefix}-vpc-endpoint-sg"
  description = "VPC endpoint security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-vpc-endpoint-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_in_1" {
  security_group_id = aws_security_group.vpc_endpoint.id

  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.vpc_lambda.id
  description                  = "from VPC Lambda Security Group"
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_in_2" {
  security_group_id = aws_security_group.vpc_endpoint.id

  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.bastion_ec2.id
  description                  = "from Bastion EC2 Security Group"
}

# Bastion用のセキュリティグループ
resource "aws_security_group" "bastion_ec2" {
  name        = "${var.name_prefix}-bastion-ec2-sg"
  description = "Bastion EC2 security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-bastion-ec2-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ec2_in_1" {
  security_group_id = aws_security_group.bastion_ec2.id

  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.vpc_endpoint.id
  description                  = "from VPC Endpoint Security Group"
}

resource "aws_vpc_security_group_egress_rule" "bastion_ec2_out_1" {
  security_group_id = aws_security_group.bastion_ec2.id

  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.vpc_endpoint.id
  description                  = "to VPC Endpoint Security Group"
}

resource "aws_vpc_security_group_egress_rule" "bastion_ec2_out_2" {
  security_group_id = aws_security_group.bastion_ec2.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
  description = "to Internet"
}

# Lambda用のセキュリティグループ
resource "aws_security_group" "vpc_lambda" {
  name        = "${var.name_prefix}-vpc-lambda-sg"
  description = "VPC Lambda security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-vpc-lambda-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "vpc_lambda_out_1" {
  security_group_id = aws_security_group.vpc_lambda.id

  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.vpc_endpoint.id
  description                  = "to VPC Endpoint Security Group"
}

resource "aws_vpc_security_group_egress_rule" "vpc_lambda_out_2" {
  security_group_id = aws_security_group.vpc_lambda.id

  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.rds_proxy.id
  description                  = "to RDS Proxy Security Group"
}

resource "aws_vpc_security_group_egress_rule" "vpc_lambda_out_3" {
  security_group_id = aws_security_group.vpc_lambda.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
  description = "to Internet"
}

# RDS Proxy用のセキュリティグループ
resource "aws_security_group" "rds_proxy" {
  name        = "${var.name_prefix}-rds-proxy-sg"
  description = "RDS Proxy security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-rds-proxy-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_proxy_in_1" {
  security_group_id = aws_security_group.rds_proxy.id

  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.vpc_lambda.id
  description                  = "from VPC Lambda Security Group"
}

resource "aws_vpc_security_group_ingress_rule" "rds_proxy_in_2" {
  security_group_id = aws_security_group.rds_proxy.id

  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.bastion_ec2.id
  description                  = "from Bastion EC2 Security Group"
}

resource "aws_vpc_security_group_egress_rule" "rds_proxy_out_1" {
  security_group_id = aws_security_group.rds_proxy.id

  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.rds.id
  description                  = "to RDS Security Group"
}

# RDS用のセキュリティグループ
resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "RDS security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_in_1" {
  security_group_id = aws_security_group.rds.id

  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.rds_proxy.id
  description                  = "from RDS Proxy Security Group"
}

##################################
# VPC Endpoint
##################################
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_app_1.id,
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]

  tags = {
    Name = "${var.name_prefix}-ec2messages-vpce"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_app_1.id,
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]

  tags = {
    Name = "${var.name_prefix}-ssm-vpce"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_app_1.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]

  tags = {
    Name = "${var.name_prefix}-ssmmessages-vpce"
  }
}

##################################
# Bastion
##################################
resource "aws_iam_role" "bastion_ec2" {
  name = "${var.name_prefix}-bastion-ec2-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

resource "aws_iam_instance_profile" "bastion_ec2" {
  name = "${var.name_prefix}-bastion-ec2-profile"
  role = aws_iam_role.bastion_ec2.name
}

resource "aws_instance" "bastion" {
  ami                    = "ami-0fd8f5842685ca887"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_app_1.id
  vpc_security_group_ids = [aws_security_group.bastion_ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion_ec2.name
  user_data              = file("user-data-bastion-ec2.sh")

  tags = {
    Name = "${var.name_prefix}-bastion"
  }
}

##################################
# Lambda
##################################
resource "aws_iam_role" "vpc_lambda" {
  name = "${var.name_prefix}-vpc-lambda-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]
}

##################################
# Frontend
##################################
# フロントエンドバケットの作成
resource "aws_s3_bucket" "front-app" {
  bucket = "${var.name_prefix}-front-app-bucket"
}

# フロントエンドバケットのブロックパブリックアクセス設定の作成
resource "aws_s3_bucket_public_access_block" "front-app" {
  bucket                  = aws_s3_bucket.front-app.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# フロントエンドバケットの暗号化設定の作成
resource "aws_s3_bucket_server_side_encryption_configuration" "front-app" {
  bucket = aws_s3_bucket.front-app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# フロントエンドバケットのウェブサイト設定の作成
resource "aws_s3_bucket_website_configuration" "front-app" {
  bucket = aws_s3_bucket.front-app.id

  index_document {
    suffix = "index.html"
  }
}

# フロントエンドバケットのバケットポリシーの作成
resource "aws_s3_bucket_policy" "front-app" {
  bucket = aws_s3_bucket.front-app.id
  policy = data.aws_iam_policy_document.front-app.json
}

# フロントエンドバケットのバケットポリシーのポリシーの作成
data "aws_iam_policy_document" "front-app" {
  statement {
    sid    = "Allow CloudFront"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::${var.aws_account_id}:root",
        aws_cloudfront_origin_access_identity.front-app.iam_arn,
      ]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "${aws_s3_bucket.front-app.arn}/*",
      aws_s3_bucket.front-app.arn
    ]
  }
}

# CloudFrontの作成
resource "aws_cloudfront_distribution" "front-app" {
  origin {
    domain_name = aws_s3_bucket.front-app.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.front-app.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.front-app.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.name_prefix}-front-app"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.front-app.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.name_prefix}-front-app"
  }
}

# CloudFrontのアクセス許可設定の作成
resource "aws_cloudfront_origin_access_identity" "front-app" {}

##################################
# Aurora
##################################
# AuroraのSecretの名前のランダム文字列（削除予定に引っかかる場合があるため）
resource "random_string" "db_secret" {
  length  = 6
  special = false
}

# AuroraのSecretの作成
resource "aws_secretsmanager_secret" "db_secret" {
  name        = "${var.name_prefix}-db-secret-${random_string.db_secret.result}"
  description = "Aurora DB Secret"
}

resource "aws_secretsmanager_secret_version" "db_secret" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username,
    password = var.db_password
  })
}

# Auroraのサブネットグループの作成
resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-dbsg"
  subnet_ids = [
    aws_subnet.private_db_1.id,
    aws_subnet.private_db_2.id
  ]

  tags = {
    Name = "${var.name_prefix}-dbsg"
  }
}

# Auroraのクラスターパラメータグループの作成
resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${var.name_prefix}-dbcpg"
  family      = "aurora-mysql5.7"
  description = "aurora-mysql5.7 cluster parameter group"

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_connection"
    value = "utf8mb4_general_ci"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_general_ci"
  }

  parameter {
    name  = "time_zone"
    value = "Asia/Tokyo"
  }

  tags = {
    Name = "${var.name_prefix}-dbcpg"
  }
}

# Auroraのパラメータグループの作成
resource "aws_db_parameter_group" "main" {
  name   = "${var.name_prefix}-dbpg"
  family = "aurora-mysql5.7"
}

# Auroraのクラスターの作成
resource "aws_rds_cluster" "main" {
  cluster_identifier = "${var.name_prefix}-cluster"
  engine             = "aurora-mysql"
  engine_version     = "5.7.mysql_aurora.2.07.9"

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  database_name   = "sample"
  master_username = var.db_username
  master_password = var.db_password

  db_cluster_parameter_group_name  = aws_rds_cluster_parameter_group.main.name
  db_instance_parameter_group_name = aws_db_parameter_group.main.name

  backup_retention_period      = 7
  preferred_backup_window      = "15:00-16:00"
  preferred_maintenance_window = "sun:17:00-sun:18:00"

  storage_encrypted = true

  skip_final_snapshot = true
  deletion_protection = false
}

# Auroraのクラスターのインスタンスの作成
resource "aws_rds_cluster_instance" "main" {
  count = 2

  identifier         = "${var.name_prefix}-db-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  preferred_maintenance_window = aws_rds_cluster.main.preferred_maintenance_window
}

# RDS Proxyを作成するためのIAMロールの作成
data "aws_iam_policy_document" "rds_proxy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_proxy" {
  name = "${var.name_prefix}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy" "rds_proxy" {
  name = "${var.name_prefix}-rds-proxy-policy"
  role = aws_iam_role.rds_proxy.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = "secretsmanager:GetSecretValue",
        Resource = aws_secretsmanager_secret.db_secret.arn
      },
      {
        Effect    = "Allow",
        Action    = "kms:Decrypt",
        Resource  = var.rds_proxy_iam_policy_kms_arn,
        Condition = {
          "StringEquals" = {
            "kms:ViaService" = "secretsmanager.${var.aws_region}.amazonaws.com"
          }
        }
      },
    ]
  })
}

# RDS Proxyの作成
resource "aws_db_proxy" "main" {
  name                   = "${var.name_prefix}-rds-proxy"
  engine_family          = "MYSQL"
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_subnet_ids         = [aws_subnet.private_db_1.id, aws_subnet.private_db_2.id]
  vpc_security_group_ids = [aws_security_group.rds_proxy.id]

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.db_secret.arn
  }
}

resource "aws_db_proxy_default_target_group" "main" {
  db_proxy_name = aws_db_proxy.main.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "main" {
  db_cluster_identifier = aws_rds_cluster.main.id
  db_proxy_name         = aws_db_proxy.main.name
  target_group_name     = aws_db_proxy_default_target_group.main.name
}

##################################
# バックエンド用 S3バケット
##################################
resource "aws_s3_bucket" "backend-app" {
  bucket = "${var.name_prefix}-backend-app-bucket"
}

# バックエンドバケットのブロックパブリックアクセス設定の作成
resource "aws_s3_bucket_public_access_block" "backend-app" {
  bucket                  = aws_s3_bucket.backend-app.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# バックエンドバケットの暗号化設定の作成
resource "aws_s3_bucket_server_side_encryption_configuration" "backend-app" {
  bucket = aws_s3_bucket.backend-app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

##################################
# アウトプット
##################################
output "private_subnet_app_1_id" {
  description = "Private Subnet for App 1 ID"
  value       = aws_subnet.private_app_1.id
}

output "private_subnet_app_2_id" {
  description = "Private Subnet for App 2 ID"
  value       = aws_subnet.private_app_2.id
}

output "vpc_lambda_security_group_id" {
  description = "VPC Lambda Security Group ID"
  value       = aws_security_group.vpc_lambda.id
}

output "vpc_lambda_role_arn" {
  description = "VPC Lambda Role ARN"
  value       = aws_iam_role.vpc_lambda.arn
}

output "rds_proxy_host" {
  description = "RDS Proxy Host"
  value       = aws_db_proxy.main.endpoint
}

output "bastion_ec2_instance_id" {
  description = "Bastion EC2 Instance ID"
  value       = aws_instance.bastion.id
}

output "cloud_front_url" {
  description = "CloudFront Domain Name"
  value       = "https://${aws_cloudfront_distribution.front-app.domain_name}"
}

output "frontend_bucket_s3_uri" {
  description = "Frontend Bucket Name"
  value       = "s3://${aws_s3_bucket.front-app.bucket}"
}
