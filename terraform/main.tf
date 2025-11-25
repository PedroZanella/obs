terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ------------------------------
# Reutilizar VPC e IGW existentes
# ------------------------------

data "aws_vpc" "existing" {
  id = var.vpc_id
}

data "aws_internet_gateway" "existing" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

# ------------------------------
# Subnet + Roteamento
# ------------------------------

resource "aws_subnet" "obs_subnet" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone
  tags = { Name = "obs-subnet" }
}

resource "aws_route_table" "obs_rt" {
  vpc_id = var.vpc_id
  tags   = { Name = "obs-rt" }
}

resource "aws_route" "obs_route" {
  route_table_id         = aws_route_table.obs_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = data.aws_internet_gateway.existing.id
}

resource "aws_route_table_association" "obs_assoc" {
  subnet_id      = aws_subnet.obs_subnet.id
  route_table_id = aws_route_table.obs_rt.id
}

# ------------------------------
# Segurança
# ------------------------------

resource "aws_key_pair" "main" {
  key_name   = "obs-key"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "obs_sg" {
  name        = "obs-sg"
  description = "Allow SSH, Grafana, Prometheus, Exporters"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana"
    from_port   = 3300
    to_port     = 3300
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Ping Exporter"
    from_port   = 9427
    to_port     = 9427
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------
# EC2 Instance
# ------------------------------

resource "aws_instance" "obs_vm" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.obs_subnet.id
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids      = [aws_security_group.obs_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io docker-compose git
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu

    cd /opt
    rm -rf observability/
    git clone ${var.github_repo_url} observability
    cd observability

    docker-compose up -d
  EOF

  tags = {
    Name        = "obs_vm"
    Environment = "dev"
    Owner       = "Pedro"
  }
}