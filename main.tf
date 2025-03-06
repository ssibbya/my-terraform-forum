provider "aws" {
  region = "us-east-1"  # Change as needed 
}

# VPC
resource "aws_vpc" "forum_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Public Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.forum_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
tags = {
  Name = "Public_subnet_1"
}
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.forum_vpc.id
  cidr_block        = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"
tags = {
  Name = "Public_subnet_2"
}
}

# Private Subnets (For EC2 & RDS)
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.forum_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
tags = {
  Name = "Private_subnet_1"
}
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.forum_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
tags = {
  Name = "Private_subnet_2"
}
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.forum_vpc.id
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.forum_vpc.id
tags = {
  Name = "PublicRT"
}
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.forum_vpc.id
tags = {
  Name = "PrivateRT"
}
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.forum_vpc.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer (ALB)
resource "aws_lb" "forum_alb" {
  name               = "forum-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

# Target Group for ALB
resource "aws_lb_target_group" "tg" {
  name     = "forum-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.forum_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.forum_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
#EC2 Security Group
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.forum_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Only ALB can access EC2
  }
egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_vpc_endpoint" "ssm" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids   = [aws_subnet.private1.id]
  security_group_ids = [aws_security_group.ssm_endpoint_sg.id]
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids   = [aws_subnet.private1.id]
  security_group_ids = [aws_security_group.ssm_endpoint_sg.id]
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids   = [aws_subnet.private1.id]
  security_group_ids = [aws_security_group.ssm_endpoint_sg.id]
}

#EC2 IAM Role
resource "aws_iam_role" "ec2_role" {
  name = "forum-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "forum-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
# EC2 Launch Template
resource "aws_launch_template" "forum_lt" {
  name_prefix   = "forum-lt"
  image_id      = "ami-05b10e08d247fb927"  # Update AMI ID
  instance_type = "t3.micro"

 network_interfaces {
    associate_public_ip_address = false  # Must remain false (private subnet)
    security_groups             = [aws_security_group.ec2_sg.id]
    subnet_id                   = aws_subnet.private1.id  # Ensure correct subnet
  }

  # Attach IAM Profile to EC2
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "Forum App Running!" > /var/www/html/index.html
            EOF
  )
}


# Auto Scaling Group
resource "aws_autoscaling_group" "forum_asg" {
  vpc_zone_identifier = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  desired_capacity    = 2
  max_size           = 3
  min_size           = 1

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.forum_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn] # Link ASG to ALB Target Group
}

#RDS Security Group
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.forum_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2_sg.id] # Only EC2 can access DB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS Database (PostgreSQL)
resource "aws_db_instance" "forum_db" {
  identifier             = "forum-db"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  max_allocated_storage  = 100
  db_name                = "forumdb"
  username              = "dbadmin"
  password              = "yourpassword"
  publicly_accessible    = false
  skip_final_snapshot    = true
  multi_az              = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.id
}

# Database Subnet Group
resource "aws_db_subnet_group" "db_subnet" {
  name       = "forum-db-subnet"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}
