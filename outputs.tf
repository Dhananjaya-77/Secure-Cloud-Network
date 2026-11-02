output "vpc_id" {
  description = "The ID of the provisioned secure VPC."
  value       = module.secure_vpc.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC."
  value       = module.secure_vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs for internet-facing Load Balancers and NAT Gateways."
  value       = module.secure_vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs for compute (EC2, ECS, EKS)."
  value       = module.secure_vpc.private_app_subnet_ids
}

output "isolated_db_subnet_ids" {
  description = "Isolated database subnet IDs (zero internet egress)."
  value       = module.secure_vpc.isolated_db_subnet_ids
}

output "db_subnet_group_name" {
  description = "RDS DB Subnet Group name for attaching to RDS/Aurora clusters."
  value       = module.secure_vpc.db_subnet_group_name
}

output "nat_gateway_public_ips" {
  description = "Outbound static public IPs of the NAT Gateways (for whitelisting in 3rd party APIs)."
  value       = module.secure_vpc.nat_gateway_public_ips
}

output "alb_security_group_id" {
  description = "Security Group ID for the Public Application Load Balancer."
  value       = module.secure_vpc.alb_security_group_id
}

output "app_security_group_id" {
  description = "Security Group ID for application workloads."
  value       = module.secure_vpc.app_security_group_id
}

output "db_security_group_id" {
  description = "Security Group ID for the isolated database tier."
  value       = module.secure_vpc.db_security_group_id
}

output "cloudwatch_flow_logs_arn" {
  description = "CloudWatch Log Group ARN where VPC Flow Logs are recorded."
  value       = module.secure_vpc.flow_log_group_arn
}
