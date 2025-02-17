provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn = var.aws_role_arn
  }
}

# VPC
resource "aws_vpc" "forum_vpc" {
  cidr_block = "10.1.0.0/16"
}

# Subnets
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.forum_vpc.id
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.forum_vpc.id
  cidr_block = "10.1.2.0/24"
}

# Security Group
resource "aws_security_group" "forum_sg" {
  vpc_id = aws_vpc.forum_vpc.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "forum_alb" {
  name               = "forum-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.forum_sg.id]
  subnets            = [aws_subnet.public_subnet.id]
}

# Auto Scaling Group
resource "aws_autoscaling_group" "forum_asg" {
  vpc_zone_identifier = [aws_subnet.public_subnet.id]
  desired_capacity    = 2
  min_size           = 1
  max_size           = 3
}

# RDS Database
resource "aws_db_instance" "forum_db" {
  allocated_storage    = 20
  engine              = "mysql"
  instance_class      = "db.t3.micro"
  username           = "admin"
  password           = "changeme123"
  vpc_security_group_ids = [aws_security_group.forum_sg.id]
  db_subnet_group_name   = aws_subnet.private_subnet.id
  skip_final_snapshot = true
}

variable "aws_region" {}
variable "aws_role_arn" {}
