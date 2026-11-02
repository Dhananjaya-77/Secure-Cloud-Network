# ------------------------------------------------------------------------------
# Network ACLs (Defense-in-depth subnet boundary firewalls)
# ------------------------------------------------------------------------------

# --- Public Tier NACL ---
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.public[*].id

  # Ingress Rules
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535 # Ephemeral return traffic
  }

  # Egress Rules
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-public-nacl"
      Tier        = "Public"
      Environment = var.environment
    }
  )
}

# --- Private Application Tier NACL ---
resource "aws_network_acl" "private_app" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.private_app[*].id

  # Ingress from VPC CIDR (ALB traffic & internal endpoints)
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 65535
  }

  # Ingress ephemeral return traffic from NAT Gateways / Internet
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Egress to anywhere (via NAT gateway) and internal VPC
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-private-app-nacl"
      Tier        = "Private-App"
      Environment = var.environment
    }
  )
}

# --- Isolated Database Tier NACL ---
resource "aws_network_acl" "isolated_db" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.isolated_db[*].id

  # Ingress strictly on database port from the Private App Subnets
  dynamic "ingress" {
    for_each = var.private_app_subnet_cidrs
    content {
      rule_no    = 100 + ingress.key
      protocol   = "tcp"
      action     = "allow"
      cidr_block = ingress.value
      from_port  = var.database_port
      to_port    = var.database_port
    }
  }

  # Egress return ephemeral traffic strictly back to Private App Subnets
  dynamic "egress" {
    for_each = var.private_app_subnet_cidrs
    content {
      rule_no    = 100 + egress.key
      protocol   = "tcp"
      action     = "allow"
      cidr_block = egress.value
      from_port  = 1024
      to_port    = 65535
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-isolated-db-nacl"
      Tier        = "Isolated-DB"
      Environment = var.environment
    }
  )
}
