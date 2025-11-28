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
  tags                    = { Name = "obs-subnet" }
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
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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

  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
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

resource "aws_instance" "obs_predo" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.obs_subnet.id
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids      = [aws_security_group.obs_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -e

    echo "🚀 Iniciando setup da VM..."

    # Adiciona usuário ao grupo docker
    sudo usermod -aG docker ubuntu
    newgrp docker


    # Instalar Docker
    if ! command -v docker &> /dev/null; then
      curl -fsSL https://get.docker.com -o get-docker.sh
      sh get-docker.sh
      usermod -aG docker ubuntu
    fi

    # Instalar Docker Compose
    if ! command -v docker-compose &> /dev/null; then
      curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      chmod +x /usr/local/bin/docker-compose
    fi

    # Clonar repositório
    cd /home/ubuntu
    git clone https://github.com/PedroZanella/obs.git
    cd obs

    # Subir containers
    docker-compose up -d
  EOF



  tags = {
    Name        = "obs-predo"
    Environment = "dev"
    Owner       = "Pedro"
  }
}