variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "Must be a valid IPv4 CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "availability_zones" {
  description = "List of Availability Zones to deploy subnets across."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (matches AZ count)."
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "List of CIDR blocks for private application subnets (matches AZ count)."
  type        = list(string)
}

variable "isolated_db_subnet_cidrs" {
  description = "List of CIDR blocks for isolated database subnets (matches AZ count)."
  type        = list(string)
}

variable "project_name" {
  description = "Project name prefix for resource naming and tagging."
  type        = string
  default     = "secure-cloud"
}

variable "environment" {
  description = "Deployment environment (e.g., prod, staging, dev)."
  type        = string
  default     = "prod"
}

variable "single_nat_gateway" {
  description = "If true, deploy only 1 NAT Gateway for all private subnets (cost-effective for non-prod). If false, deploy 1 NAT Gateway per AZ for high availability."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs sent to CloudWatch."
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Specifies the number of days you want to retain log events in the CloudWatch log group."
  type        = number
  default     = 30
}

variable "enable_s3_endpoint" {
  description = "Enable S3 Gateway Endpoint to route S3 traffic internally within AWS."
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Enable DynamoDB Gateway Endpoint to route DynamoDB traffic internally."
  type        = bool
  default     = true
}

variable "enable_ssm_endpoints" {
  description = "Enable Interface VPC Endpoints for AWS Systems Manager (SSM) Session Manager to allow secure terminal access without SSH keys or public IPs."
  type        = bool
  default     = true
}

variable "database_port" {
  description = "Database port for the DB security group ingress rule (e.g. 5432 for Postgres, 3306 for MySQL)."
  type        = number
  default     = 5432
}

variable "tags" {
  description = "Additional tags applied to all VPC resources."
  type        = map(string)
  default     = {}
}
