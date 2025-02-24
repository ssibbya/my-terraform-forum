provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "forum_vpc" {
  cidr_block = "10.1.0.0/16"
tags = {
Name = "forum_vpc"
}
}

# Public Subnet 1 in us-east-1a
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.forum_vpc.id
  cidr_block              = "10.1.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
tags = {
Name = "public_subnet_1"
}
}

# Public Subnet 2 in us-east-1b
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.forum_vpc.id
  cidr_block              = "10.1.20.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
tags = {
Name = "public_subnet_2"
}
}

# Internet Gateway
resource "aws_internet_gateway" "forum_igw" {
  vpc_id = aws_vpc.forum_vpc.id
tags = {
Name = "forum_igw"
}
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.forum_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.forum_igw.id
  }
tags = {
Name = "public_rt"
}
}

# Associate Public Route Table with Public Subnets
resource "aws_route_table_association" "public_rt_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Subnet 1 for RDS
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.forum_vpc.id
  cidr_block              = "10.1.30.0/24"
  availability_zone       = "us-east-1a"
tags = {
Name = "private_subnet_1"
}
}

# Private Subnet 2 (for RDS in different AZ)
resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.forum_vpc.id
  cidr_block              = "10.1.40.0/24"
  availability_zone       = "us-east-1b"
tags = {
Name = "private_subnet_2"
}
}
# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
tags = {
Name = "nat_eip"
}
}

# NAT Gateway (placed in a public subnet)
resource "aws_nat_gateway" "forum_nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
tags = {
Name = "forum_nat_igw"
}
}

# Private Route Table (NAT for Internet Access)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.forum_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.forum_nat_gw.id
  }
tags = {
Name = "private_rt"
}
}

# Associate Private Route Table with Private Subnets
resource "aws_route_table_association" "private_rt_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
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
tags = {
Name = "forum_sg"
}
}

# Modify ALB to use both subnets
resource "aws_lb" "forum_alb" {
  name               = "forum-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.forum_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
tags = {
Name = "forum_alb"
}
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

resource "aws_autoscaling_group" "forum_asg" {
  vpc_zone_identifier = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id] # Use both public subnets
  desired_capacity    = 2
  min_size           = 1
  max_size           = 3

  launch_template {
    id      = aws_launch_template.forum_lt.id
    version = "$Latest"
  }
}

# DB Subnet Group for RDS
resource "aws_db_subnet_group" "forum_db_subnet_group" {
  name       = "forum-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id] # Two subnets in different AZs
  description = "Subnet group for forum database"
tags = {
Name = "forum_db_subnet_group"
}
}

# Modify RDS to reference the DB subnet group
resource "aws_db_instance" "forum_db" {
  allocated_storage    = 20
  engine              = "mysql"
  instance_class      = "db.t3.micro"
  username           = "admin"
  password           = "changeme123"
  vpc_security_group_ids = [aws_security_group.forum_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.forum_db_subnet_group.name
  skip_final_snapshot = true
tags = {
Name = "forum_db"
}
}

