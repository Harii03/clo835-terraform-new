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

# ECR Repository for WebApp
resource "aws_ecr_repository" "webapp_repo" {
  name = "clo835-webapp"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "clo835-webapp"
  }
}

# ECR Repository for MySQL (if you need custom MySQL image)
resource "aws_ecr_repository" "mysql_repo" {
  name = "clo835-mysql"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "clo835-mysql"
  }
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

  ingress {
    from_port   = 8081
    to_port     = 8083
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
  instance_type          = "t2.medium"
  key_name               = "Assignment - 1"
  vpc_security_group_ids = [aws_security_group.clo_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker git
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -a -G docker ec2-user
              EOF

  tags = {
    Name = "clo-835"
  }
}

output "instance_public_ip" {
  value = aws_instance.clo_835.public_ip
}

output "webapp_ecr_url" {
  value = aws_ecr_repository.webapp_repo.repository_url
}

output "mysql_ecr_url" {
  value = aws_ecr_repository.mysql_repo.repository_url
}
