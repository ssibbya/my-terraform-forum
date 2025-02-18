provider "aws" {
  region = us-east-1
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

# Launch Template
resource "aws_launch_template" "forum_lt" {
  name_prefix   = "forum-template"
  image_id      = "ami-053a45fff0a704a47"
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.forum_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ForumInstance"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "forum_asg" {
  vpc_zone_identifier = [aws_subnet.public_subnet.id]
  desired_capacity    = 2
  min_size           = 1
  max_size           = 3

  launch_template {
    id      = aws_launch_template.forum_lt.id
    version = "$Latest"
  }
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
