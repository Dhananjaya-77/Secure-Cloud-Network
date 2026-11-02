variable "aws_region" {
  description = "AWS region to deploy the infrastructure."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix."
  type        = string
  default     = "secure-network"
}

variable "environment" {
  description = "Target deployment environment."
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "VPC supernet CIDR block."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to span."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public tier subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application tier subnets."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "isolated_db_subnet_cidrs" {
  description = "CIDR blocks for isolated persistence/database subnets."
  type        = list(string)
  default     = ["10.0.100.0/24", "10.0.200.0/24"]
}

variable "single_nat_gateway" {
  description = "Set to true for staging/dev to reduce cost, or false for multi-AZ HA in production."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable CloudWatch VPC flow logs for network visibility and threat detection."
  type        = bool
  default     = true
}

variable "enable_s3_endpoint" {
  description = "Enable AWS S3 Gateway Endpoint to avoid NAT charges and secure data in-transit."
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Enable AWS DynamoDB Gateway Endpoint."
  type        = bool
  default     = true
}

variable "enable_ssm_endpoints" {
  description = "Enable Interface Endpoints for AWS Systems Manager (SSM) agent access without SSH."
  type        = bool
  default     = true
}

variable "database_port" {
  description = "Port to allow into DB subnets from App subnets (e.g., 5432 for PostgreSQL, 3306 for MySQL)."
  type        = number
  default     = 5432
}
