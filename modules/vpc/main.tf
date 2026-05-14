locals {
  selected_azs = slice(data.aws_availability_zones.available.names, 0, tonumber(var.number_of_azs))

  private_subnet_cidrs = [
    for i in range(tonumber(var.number_of_azs)) :
    cidrsubnet(var.vpc_cidr, var.cluster_name != "" ? 4 : 8, i)
  ]

  public_subnet_cidrs = [for i in range(tonumber(var.number_of_azs)) : cidrsubnet(var.vpc_cidr, 8, i + 10)]
  data_subnet_cidrs   = [for i in range(tonumber(var.number_of_azs)) : cidrsubnet(var.vpc_cidr, 8, i + 20)]

  app_subnets    = var.create_app_subnets ? zipmap(local.selected_azs, local.private_subnet_cidrs) : {}
  public_subnets = var.create_public_subnets ? zipmap(local.selected_azs, local.public_subnet_cidrs) : {}
  data_subnets   = var.create_data_subnets ? zipmap(local.selected_azs, local.data_subnet_cidrs) : {}
}


################################################################################
# VPC
################################################################################
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  assign_generated_ipv6_cidr_block = var.enable_ipv6

  tags = merge(local.tags,
    { Name = "${var.customer_name}-${var.environment}-vpc" }
  )
}

################################################################################
# DHCP Options
################################################################################
resource "aws_vpc_dhcp_options" "dhcp_options" {
  domain_name         = "${data.aws_region.current.name}.compute.internal"
  domain_name_servers = ["8.8.8.8", "8.8.4.4"]
  ntp_servers         = ["127.0.0.1"]
  tags = {
    Name = "${var.customer_name}-${var.environment}-dhcp"
  }
}

resource "aws_vpc_dhcp_options_association" "dhcp_association" {
  vpc_id          = aws_vpc.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dhcp_options.id
}

################################################################################
# Internet and NAT Gateways
################################################################################
resource "aws_internet_gateway" "igw" {
  count = var.create_public_subnets ? 1 : 0

  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.customer_name}-${var.environment}-igw"
  }
}

resource "aws_eip" "eip" {
  count = var.create_nat && var.create_public_subnets ? (var.nat_gateway_high_availability ? length(local.public_subnets) : 1) : 0

  tags = {
    Name = var.nat_gateway_high_availability ? "eip-nat-gw-${count.index}" : "eip-nat-gw"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_gw" {
  count = var.create_nat && var.create_public_subnets ? (var.nat_gateway_high_availability ? length(local.public_subnets) : 1) : 0

  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = var.nat_gateway_high_availability ? element(aws_subnet.public_subnet.*.id, count.index) : element(aws_subnet.public_subnet.*.id, 0)
  tags = {
    Name = var.nat_gateway_high_availability ? "${var.customer_name}-${var.environment}-nat-gateway-${count.index}" : "${var.customer_name}-${var.environment}-nat-gateway"
  }
}

################################################################################
# Subnets
################################################################################

resource "aws_subnet" "app_subnet" {
  count             = var.create_app_subnets ? length(local.app_subnets) : 0
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(values(local.app_subnets), count.index)
  availability_zone = element(keys(local.app_subnets), count.index)

  tags = merge(
    {
      Name                     = "${var.customer_name}-${var.environment}-private-subnet-${element(keys(local.app_subnets), count.index)}"
      "karpenter.sh/discovery" = "${var.cluster_name}"
    }
  )
}

resource "aws_subnet" "public_subnet" {
  count             = var.create_public_subnets ? length(local.public_subnets) : 0
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(values(local.public_subnets), count.index)
  availability_zone = element(keys(local.public_subnets), count.index)

  tags = {
    Name                     = "${var.customer_name}-${var.environment}-public-subnet-${element(keys(local.public_subnets), count.index)}"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "data_subnet" {
  count             = var.create_data_subnets ? length(local.data_subnets) : 0
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(values(local.data_subnets), count.index)
  availability_zone = element(keys(local.data_subnets), count.index)

  tags = {
    Name = "${var.customer_name}-${var.environment}-data-subnet-${element(keys(local.data_subnets), count.index)}"
  }
}

################################################################################
# Route Tables
################################################################################

resource "aws_route_table" "app_route_table" {
  count  = var.create_app_subnets ? length(local.app_subnets) : 0
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.customer_name}-${var.environment}-private-route-table-${element(keys(local.app_subnets), count.index)}"
  }
}

resource "aws_route_table" "public_route_table" {
  count  = var.create_public_subnets ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = {
    Name = "${var.customer_name}-${var.environment}-public-route-table"
  }
}

resource "aws_route_table" "data_route_table" {
  count  = var.create_data_subnets ? length(local.data_subnets) : 0
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.customer_name}-${var.environment}-data-route-table-${element(keys(local.data_subnets), count.index)}"
  }
}

################################################################################
# Routes
################################################################################
resource "aws_route" "private_route" {
  count                  = var.create_nat && var.nat_gateway_high_availability && var.create_app_subnets ? length(local.app_subnets) : 0
  route_table_id         = element(aws_route_table.app_route_table.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw[count.index].id
  depends_on             = [aws_route_table.app_route_table]
}

resource "aws_route" "single_nat_route" {
  count                  = var.create_nat && !var.nat_gateway_high_availability && var.create_app_subnets ? length(local.app_subnets) : 0
  route_table_id         = element(aws_route_table.app_route_table.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw[0].id
  depends_on             = [aws_route_table.app_route_table]
}

################################################################################
# Route Table Associations
################################################################################
resource "aws_route_table_association" "public_route_table_association" {
  count          = var.create_public_subnets ? length(local.public_subnets) : 0
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_route_table[0].id
}

resource "aws_route_table_association" "app_route_table_association" {
  count          = var.create_app_subnets ? length(local.app_subnets) : 0
  subnet_id      = element(aws_subnet.app_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.app_route_table.*.id, count.index)
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_route_table_association" "data_route_table_association" {
  count          = var.create_data_subnets ? length(local.data_subnets) : 0
  subnet_id      = element(aws_subnet.data_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.data_route_table.*.id, count.index)
  lifecycle {
    ignore_changes = all
  }
}

################################################################################
# Data Subnet Group
################################################################################
resource "aws_db_subnet_group" "data_subnet_group" {
  count = var.create_data_subnets ? 1 : 0

  name       = "${var.customer_name}-${var.environment}-data-subnet-group"
  subnet_ids = aws_subnet.data_subnet.*.id

  tags = {
    Name = "${var.customer_name}-${var.environment}-data-subnet-group"
  }
  lifecycle {
    ignore_changes = all
  }
}

