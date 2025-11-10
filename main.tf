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

# ECR Repository - this usually works even with restricted permissions
resource "aws_ecr_repository" "clo835_repo" {
  name = "clo835-assignment1-app"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "clo835-ecr"
  }
}

resource "aws_security_group" "clo_sg" {
  name        = "clo-835-sg"
  description = "Security group for CLO-835 instance"

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Application ports
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
  ami                    = "ami-0157af9aea2eef346"  # Amazon Linux 2023
  instance_type          = "t2.micro"
  key_name               = "Assignment - 1"
  vpc_security_group_ids = [aws_security_group.clo_sg.id]

  # User data to install Docker and git on startup
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
  description = "Public IP address of the EC2 instance"
}

output "ecr_repository_url" {
  value = aws_ecr_repository.clo835_repo.repository_url
  description = "ECR repository URL for Docker images"
}
