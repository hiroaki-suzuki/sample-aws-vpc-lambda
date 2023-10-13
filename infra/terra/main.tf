terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.21.0"
    }
  }
}

provider "aws" {
  region     = "ap-northeast-1"
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
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_a_cidr
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "${var.name_prefix}-public-subnet-a"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_c_cidr
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "${var.name_prefix}-public-subnet-c"
  }
}

resource "aws_subnet" "private_app_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_app_a_cidr
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "${var.name_prefix}-private-app-subnet-a"
  }
}

resource "aws_subnet" "private_app_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_app_c_cidr
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "${var.name_prefix}-private-app-subnet-c"
  }
}

resource "aws_subnet" "private_db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_db_a_cidr
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "${var.name_prefix}-private-db-subnet-a"
  }
}

resource "aws_subnet" "private_db_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_db_c_cidr
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "${var.name_prefix}-private-db-subnet-c"
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
resource "aws_eip" "ngw_a" {
  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}-ngw-eip-a"
  }
}

resource "aws_nat_gateway" "ngw_a" {
  allocation_id = aws_eip.ngw_a.id
  subnet_id     = aws_subnet.public_a.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.name_prefix}-ngw-a"
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

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw_a.id
  }

  tags = {
    Name = "${var.name_prefix}-private-app-rtb"
  }
}

resource "aws_route_table_association" "private_app_a" {
  subnet_id      = aws_subnet.private_app_a.id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_route_table_association" "private_app_c" {
  subnet_id      = aws_subnet.private_app_c.id
  route_table_id = aws_route_table.private_app.id
}

##################################
# Security Group
##################################
resource "aws_security_group" "vpc_endpoint" {
  name        = "${var.name_prefix}-vpc-endpoint-sg"
  description = "VPC endpoint security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-vpc-endpoint-sg"
  }
}

resource "aws_security_group" "bastion_ec2" {
  name        = "${var.name_prefix}-bastion-ec2-sg"
  description = "Bastion EC2 security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.vpc_endpoint.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-bastion-ec2-sg"
  }
}

resource "aws_security_group" "vpc_lambda" {
  name        = "${var.name_prefix}-vpc-lambda-sg"
  description = "VPC Lambda security group"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-vpc-lambda-sg"
  }
}

##################################
# VPC Endpoint
##################################
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_app_a.id,
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]

  tags = {
    Name = "${var.name_prefix}-vpc-endpoint-ec2messages-vpce"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_app_a.id,
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]

  tags = {
    Name = "${var.name_prefix}-vpc-endpoint-ssm-vpce"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_app_a.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]

  tags = {
    Name = "${var.name_prefix}-vpc-endpoint-ssmmessages-vpce"
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
  subnet_id              = aws_subnet.private_app_a.id
  vpc_security_group_ids = [aws_security_group.bastion_ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion_ec2.name

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