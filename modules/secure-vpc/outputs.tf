output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets."
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks of public subnets."
  value       = aws_subnet.public[*].cidr_block
}

output "private_app_subnet_ids" {
  description = "List of IDs of private application subnets."
  value       = aws_subnet.private_app[*].id
}

output "private_app_subnet_cidrs" {
  description = "List of CIDR blocks of private application subnets."
  value       = aws_subnet.private_app[*].cidr_block
}

output "isolated_db_subnet_ids" {
  description = "List of IDs of isolated database subnets."
  value       = aws_subnet.isolated_db[*].id
}

output "isolated_db_subnet_cidrs" {
  description = "List of CIDR blocks of isolated database subnets."
  value       = aws_subnet.isolated_db[*].cidr_block
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways."
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public Elastic IPs associated with the NAT Gateways."
  value       = aws_eip.nat[*].public_ip
}

output "db_subnet_group_name" {
  description = "The name of the RDS DB Subnet Group."
  value       = aws_db_subnet_group.this.name
}

output "db_subnet_group_id" {
  description = "The ID of the RDS DB Subnet Group."
  value       = aws_db_subnet_group.this.id
}

output "alb_security_group_id" {
  description = "The ID of the Public ALB Security Group."
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "The ID of the Private Application Security Group."
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "The ID of the Isolated Database Security Group."
  value       = aws_security_group.db.id
}

output "default_security_group_id" {
  description = "The ID of the hardened default security group (all traffic denied)."
  value       = aws_default_security_group.default.id
}

output "flow_log_id" {
  description = "The ID of the VPC Flow Log."
  value       = try(aws_flow_log.this[0].id, null)
}

output "flow_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for VPC Flow Logs."
  value       = try(aws_cloudwatch_log_group.flow_logs[0].arn, null)
}
