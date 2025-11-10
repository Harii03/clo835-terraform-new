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

# ECR Repository for your Docker images
resource "aws_ecr_repository" "clo835_repo" {
  name = "clo835-assignment1-app"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "clo835-ecr"
  }
}

# IAM Role for EC2 to access ECR
resource "aws_iam_role" "ec2_ecr_role" {
  name = "ec2-ecr-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for ECR access
resource "aws_iam_role_policy" "ecr_policy" {
  name = "ecr-access-policy"
  role = aws_iam_role.ec2_ecr_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ecr-instance-profile"
  role = aws_iam_role.ec2_ecr_role.name
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
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # User data to install Docker on startup
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
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

output "ecr_repository_url" {
  value = aws_ecr_repository.clo835_repo.repository_url
}

output "ecr_repository_name" {
  value = aws_ecr_repository.clo835_repo.name
}
