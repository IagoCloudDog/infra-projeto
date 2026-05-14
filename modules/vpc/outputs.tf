output "vpc_id" {
  description = "The ID of the VPC created"
  value       = aws_vpc.vpc.id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway associated with the VPC"
  value       = aws_internet_gateway.igw[0].id
}

output "nat_gateway_ids" {
  description = "A list of IDs for the NAT Gateways created"
  value       = [for nat_gw in aws_nat_gateway.nat_gw : nat_gw.id]
}

output "app_subnet_ids" {
  description = "A list of IDs for the application subnets created"
  value       = [for subnet in aws_subnet.app_subnet : subnet.id]
}

output "public_subnet_ids" {
  description = "A list of IDs for the public subnets created"
  value       = [for subnet in aws_subnet.public_subnet : subnet.id]
}

output "data_subnet_ids" {
  description = "A list of IDs for the data subnets created"
  value       = [for subnet in aws_subnet.data_subnet : subnet.id]
}

output "data_subnet_group" {
  description = "Data subnet group for database"
  value       = aws_db_subnet_group.data_subnet_group[0].id
}

output "data_subnet_group_name" {
  description = "Data subnet group for database"
  value       = aws_db_subnet_group.data_subnet_group[0].name
}

output "cidr_block" {
  value = aws_vpc.vpc.cidr_block
}

output "vpc_base_ip" {
  description = "The base IP of the VPC without CIDR notation"
  value       = split("/", aws_vpc.vpc.cidr_block)[0]
}