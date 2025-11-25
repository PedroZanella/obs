variable "vpc_id" {
  description = "ID da VPC existente"
  type        = string
  default     = "vpc-06786ee7f7a163059"
}

variable "public_key_path" {
  description = "Caminho da chave pública para acesso SSH"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "subnet_cidr" {
  description = "CIDR da Subnet pública"
  type        = string
  default     = "172.30.250.0/24" # ajuste conforme o bloco da VPC
}

variable "availability_zone" {
  description = "Zona de disponibilidade da Subnet"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI para Ubuntu Server"
  type        = string
  default     = "ami-0fc5d935ebf8bc3bc"
}

