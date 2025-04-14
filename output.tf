output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.forum_alb.dns_name
}

output "rds_endpoint" {
  description = "The endpoint of the PostgreSQL RDS database"
  value       = aws_db_instance.forum_db.endpoint
}

output "vpc_id" {
  description = "The ID of the VPC created"
  value       = aws_vpc.forum_vpc.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]
}
