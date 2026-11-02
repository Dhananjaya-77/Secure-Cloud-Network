# ------------------------------------------------------------------------------
# CIS AWS Foundations Benchmark 5.4:
# Restrict all traffic for the default security group of the VPC.
# This prevents accidental attachment of default security group with open rules.
# ------------------------------------------------------------------------------
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id

  # Leaving ingress and egress empty removes all default rules (Deny All)
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-default-sg-hardened"
      Description = "CIS hardened default SG - All traffic denied"
      Environment = var.environment
    }
  )
}

# ------------------------------------------------------------------------------
# Public ALB Security Group (Internet Ingress -> Public Load Balancer)
# ------------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for public application load balancer"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Allow HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound to VPC workloads"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-alb-sg"
      Environment = var.environment
    }
  )
}

# ------------------------------------------------------------------------------
# Private Application Tier Security Group (Workloads / EC2 / ECS / EKS)
# ------------------------------------------------------------------------------
resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Security group for private application workloads"
  vpc_id      = aws_vpc.this.id

  # Ingress strictly from ALB security group
  ingress {
    description     = "Inbound application traffic from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Inbound HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow outbound internet via NAT gateway (e.g. for updates, external APIs)
  egress {
    description = "Allow outbound internet traffic via NAT Gateway"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-app-sg"
      Environment = var.environment
    }
  )
}

# ------------------------------------------------------------------------------
# Isolated Database Tier Security Group (RDS / Aurora)
# ------------------------------------------------------------------------------
resource "aws_security_group" "db" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Security group for isolated database tier"
  vpc_id      = aws_vpc.this.id

  # Ingress strictly allowed on the DB port from the Application tier SG
  ingress {
    description     = "Database access strictly from application security group"
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # Zero egress to internet: DB instances cannot communicate outside their tier
  egress {
    description = "Local VPC response only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-db-sg"
      Environment = var.environment
    }
  )
}
