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

resource "aws_security_group" "clo_sg" {
  name        = "clo-835-sg"
  description = "Security group for CLO-835 instance"

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "clo-835-sg"
  }
}

resource "aws_instance" "clo_835" {
  ami                    = "ami-0157af9aea2eef346"
  instance_type          = "t2.micro"
  key_name               = "Assignment - 1"
  vpc_security_group_ids = [aws_security_group.clo_sg.id]

  tags = {
    Name = "clo-835"
  }
}

output "instance_public_ip" {
  value = aws_instance.clo_835.public_ip
}
