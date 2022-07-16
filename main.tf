provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*"]
    # 2.0.20220606.1-x86_64-gp2
  }
}

variable "ingressrules" {
  type    = list(number)
  default = [80]
}

variable "egressrules" {
  type    = list(number)
  default = [80]
}

resource "aws_security_group" "minecraft_security_group" {
  name = "minecraft-security-group"

  dynamic "ingress" {
    iterator = port
    for_each = var.ingressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "egress" {
    iterator = port
    for_each = var.egressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}


resource "aws_instance" "minecraft_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  security_groups = [aws_security_group.minecraft_security_group.name]

  tags = {
    Name = "Mincraft Server"
  }
}
