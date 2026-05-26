# ============================================================
# arquitectura.tf — Infraestructura como Código
# Proyecto Final Telemática
#
# Despliega en AWS:
#   - 1 instancia EC2 t2.micro (capa gratuita)
#   - Security Group con puertos 22, 80 y 443 abiertos
#   - User data script que instala Docker y levanta la app
#
# Requisitos previos:
#   1. Instalar Terraform: https://developer.hashicorp.com/terraform/downloads
#   2. Configurar credenciales AWS: aws configure
#   3. Crear un key pair en AWS Console → EC2 → Key Pairs
#      y guardar el archivo .pem
#
# Uso:
#   terraform init      # descarga providers
#   terraform plan      # previsualiza cambios
#   terraform apply     # crea la infraestructura
#   terraform destroy   # destruye todo (evita cargos)
# ============================================================


# ── Provider: AWS ───────────────────────────────────────────
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region   # definido en variables más abajo
}


# ── Variables ────────────────────────────────────────────────

variable "aws_region" {
  description = "Región de AWS donde se desplegará la infraestructura"
  type        = string
  default     = "us-east-1"   # N. Virginia — incluida en capa gratuita
}

variable "key_pair_name" {
  description = "Nombre del Key Pair creado en AWS Console (sin .pem)"
  type        = string
  default     = "vockey"   # CAMBIAR por el nombre de tu key pair
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t2.micro"   # capa gratuita de AWS (750 h/mes)
}


# ── Datos: obtener AMI más reciente de Amazon Linux 2023 ────
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# ── Security Group ───────────────────────────────────────────
# Define qué tráfico de red entra y sale de la instancia EC2
resource "aws_security_group" "telematica_sg" {
  name        = "telematica-security-group"
  description = "Security group para la app de telemática"

  # Puerto 22 — SSH (para administrar el servidor)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # En producción real: limitar a tu IP
  }

  # Puerto 80 — HTTP (tráfico web normal)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Puerto 443 — HTTPS (tráfico web seguro, para futuras mejoras)
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Salida: permitir todo el tráfico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "telematica-sg"
    Proyecto  = "Telemática"
    Semestre  = "3"
  }
}


# ── Instancia EC2 ────────────────────────────────────────────
resource "aws_instance" "telematica_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.telematica_sg.id]

  # user_data: script que se ejecuta automáticamente la primera vez que arranca
  # Instala Docker, clona el repo y levanta la app
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Actualizar sistema
    yum update -y

    # Instalar Docker
    yum install -y docker git
    systemctl start docker
    systemctl enable docker

    # Agregar el usuario ec2-user al grupo docker
    usermod -aG docker ec2-user

    # Instalar Docker Compose v2
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
         -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

    # Clonar el repositorio del proyecto
    # IMPORTANTE: reemplazar por la URL de tu repositorio en GitHub
    cd /home/ec2-user
    git clone https://github.com/TU_USUARIO/proyecto-telematica.git app
    cd app

    # Levantar la aplicación con Docker Compose
    docker compose up -d --build

    echo "Despliegue completado exitosamente" >> /var/log/user-data.log
  EOF

  # Almacenamiento: 20 GB de disco (suficiente para la app e imágenes Docker)
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name      = "telematica-server"
    Proyecto  = "Telemática"
    Semestre  = "3"
  }
}


# ── Outputs ──────────────────────────────────────────────────
# Valores que Terraform muestra al terminar el apply

output "ip_publica" {
  description = "Dirección IP pública del servidor"
  value       = aws_instance.telematica_server.public_ip
}

output "dns_publico" {
  description = "DNS público del servidor"
  value       = aws_instance.telematica_server.public_dns
}

output "url_aplicacion" {
  description = "URL para acceder a la aplicación"
  value       = "http://${aws_instance.telematica_server.public_ip}"
}

output "comando_ssh" {
  description = "Comando para conectarse al servidor por SSH"
  value       = "ssh -i ${var.key_pair_name}.pem ec2-user@${aws_instance.telematica_server.public_ip}"
}
