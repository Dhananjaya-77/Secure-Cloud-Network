# ------------------------------------------------------------------------------
# Root Module: Secure Cloud Network VPC Deployment
# ------------------------------------------------------------------------------
module "secure_vpc" {
  source = "./modules/secure-vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  isolated_db_subnet_cidrs = var.isolated_db_subnet_cidrs

  single_nat_gateway       = var.single_nat_gateway
  enable_flow_logs         = var.enable_flow_logs
  enable_s3_endpoint       = var.enable_s3_endpoint
  enable_dynamodb_endpoint = var.enable_dynamodb_endpoint
  enable_ssm_endpoints     = var.enable_ssm_endpoints
  database_port            = var.database_port

  tags = {
    Owner     = "DevOps/SecOps"
    Framework = "AWS-Well-Architected"
  }
}
