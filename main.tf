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

# resource "aws_iam_role_policy" "minecraft_server_toggle_policy" {
#   name = "minecraft-server-toggle-policy"
#   role = aws_iam_role.minecraft_server_lambda_toggle

#   policy = jsoncode({
#     Statement : [
#       {
#         Effect : "Allow",
#         Action : [
#           "ec2:StartInstances",
#           "ec2:StopInstances"
#         ],
#         Resource : [
#           "arn:aws:ec2:*:531238205865:instance/*",
#           "arn:aws:license-manager:*:531238205865:license-configuration/*"
#         ]
#       },
#     ]
#   })
# }

data "aws_iam_policy_document" "instance_toggle_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "minecraft_server_lambda_toggle" {
  name               = "minecraft-server-lambda-toggle"
  assume_role_policy = data.aws_iam_policy_document.instance_toggle_role_policy.json
}

resource "aws_lambda_function" "mincraft_server_toggle" {
  function_name = "lambda_minecraft_server_toggle"
  role          = aws_iam_role.minecraft_server_lambda_toggle.arn
  handler       = "app.py"
  runtime       = "python3.9"
}

resource "aws_cloudwatch_event_rule" "toggle_event_rule" {
  name        = "toggle-event-rule"
  description = "Runs lambda to toggle on and off Minecraft server"

  schedule_expression = "cron(0 8 * * ? *)"
}

