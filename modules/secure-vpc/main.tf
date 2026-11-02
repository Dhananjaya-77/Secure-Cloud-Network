# ------------------------------------------------------------------------------
# VPC Definition
# ------------------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-vpc"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# ------------------------------------------------------------------------------
# Internet Gateway (for Public Subnets)
# ------------------------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-igw"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# ------------------------------------------------------------------------------
# Public Subnets (ALB / Ingress / NAT Gateways)
# ------------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false # Security best practice: don't automatically assign public IPs

  tags = merge(
    var.tags,
    {
      Name                     = "${var.project_name}-${var.environment}-public-${var.availability_zones[count.index]}"
      Tier                     = "Public"
      Environment              = var.environment
      "kubernetes.io/role/elb" = "1" # Helpful for ingress load balancers if EKS is used
    }
  )
}

# ------------------------------------------------------------------------------
# Private Application Subnets (Compute / Containers / Workloads)
# ------------------------------------------------------------------------------
resource "aws_subnet" "private_app" {
  count                   = length(var.private_app_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_app_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name                              = "${var.project_name}-${var.environment}-private-app-${var.availability_zones[count.index]}"
      Tier                              = "Private-App"
      Environment                       = var.environment
      "kubernetes.io/role/internal-elb" = "1"
    }
  )
}

# ------------------------------------------------------------------------------
# Isolated Database Subnets (RDS / Aurora / ElastiCache)
# ------------------------------------------------------------------------------
resource "aws_subnet" "isolated_db" {
  count                   = length(var.isolated_db_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.isolated_db_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-isolated-db-${var.availability_zones[count.index]}"
      Tier        = "Isolated-DB"
      Environment = var.environment
    }
  )
}

# ------------------------------------------------------------------------------
# Elastic IPs and NAT Gateways for Private Egress
# ------------------------------------------------------------------------------
locals {
  nat_gateway_count = var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)
}

resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count         = local.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-nat-gw-${count.index + 1}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

# ------------------------------------------------------------------------------
# Route Tables: Public Subnets
# ------------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-public-rt"
      Tier        = "Public"
      Environment = var.environment
    }
  )
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------------------------
# Route Tables: Private Application Subnets (Outbound via NAT Gateway)
# ------------------------------------------------------------------------------
resource "aws_route_table" "private_app" {
  count  = length(var.private_app_subnet_cidrs)
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-private-app-rt-${var.availability_zones[count.index]}"
      Tier        = "Private-App"
      Environment = var.environment
    }
  )
}

resource "aws_route_table_association" "private_app" {
  count          = length(var.private_app_subnet_cidrs)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

# ------------------------------------------------------------------------------
# Route Tables: Isolated Database Subnets (Strictly Internal - No IGW/NAT)
# ------------------------------------------------------------------------------
resource "aws_route_table" "isolated_db" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-isolated-db-rt"
      Tier        = "Isolated-DB"
      Environment = var.environment
    }
  )
}

resource "aws_route_table_association" "isolated_db" {
  count          = length(var.isolated_db_subnet_cidrs)
  subnet_id      = aws_subnet.isolated_db[count.index].id
  route_table_id = aws_route_table.isolated_db.id
}

# ------------------------------------------------------------------------------
# RDS DB Subnet Group (for immediate RDS/Aurora database provisioning)
# ------------------------------------------------------------------------------
resource "aws_db_subnet_group" "this" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Database subnet group for ${var.project_name} in ${var.environment}"
  subnet_ids  = aws_subnet.isolated_db[*].id

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-db-subnet-group"
      Environment = var.environment
    }
  )
}
