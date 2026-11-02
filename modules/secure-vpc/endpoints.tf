# ------------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------------
data "aws_region" "current" {}

# ------------------------------------------------------------------------------
# VPC Gateway Endpoints (Free, high-throughput, private AWS backbone routing)
# ------------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_s3_endpoint ? 1 : 0
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  # Route table associations: both private app and isolated db tiers can access S3 securely
  route_table_ids = concat(
    aws_route_table.private_app[*].id,
    [aws_route_table.isolated_db.id]
  )

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-vpce-s3"
      Environment = var.environment
    }
  )
}

resource "aws_vpc_endpoint" "dynamodb" {
  count             = var.enable_dynamodb_endpoint ? 1 : 0
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    aws_route_table.private_app[*].id,
    [aws_route_table.isolated_db.id]
  )

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-vpce-dynamodb"
      Environment = var.environment
    }
  )
}

# ------------------------------------------------------------------------------
# Interface VPC Endpoints for AWS Systems Manager (SSM)
# Allows secure session management into private instances without SSH / bastion
# ------------------------------------------------------------------------------
resource "aws_security_group" "vpc_endpoints" {
  count       = var.enable_ssm_endpoints ? 1 : 0
  name        = "${var.project_name}-${var.environment}-vpc-endpoints-sg"
  description = "Security group for SSM interface VPC endpoints"
  vpc_id      = aws_vpc.this.id

  # Allow inbound HTTPS (port 443) strictly from private application subnets
  ingress {
    description = "HTTPS from private app subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_app_subnet_cidrs
  }

  egress {
    description = "Allow all outbound (endpoints respond back)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-endpoints-sg"
      Environment = var.environment
    }
  )
}

locals {
  ssm_services = var.enable_ssm_endpoints ? ["ssm", "ssmmessages", "ec2messages"] : []
}

resource "aws_vpc_endpoint" "ssm" {
  for_each            = toset(local.ssm_services)
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_app[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-vpce-${each.key}"
      Environment = var.environment
    }
  )
}
