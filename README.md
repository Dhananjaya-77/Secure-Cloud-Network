# Secure AWS Cloud Network Architecture (3-Tier Multi-AZ)

This repository provides a modular, production-ready, and hardened **AWS Virtual Private Cloud (VPC)** built in **Terraform**, engineered to comply with the **AWS Well-Architected Framework (Security & Reliability Pillars)** and **CIS AWS Foundations Benchmarks**.

---

## 🏛️ Network Topology & Architecture

The architecture enforces strict network isolation and defense-in-depth across multiple Availability Zones:

```
                                   Internet
                                      │
                                      ▼
                           [ Internet Gateway (IGW) ]
                                      │
  ┌───────────────────────────────────┴───────────────────────────────────┐
  │                           Public Subnets                              │
  │   - No auto-assigned public IPs (Strict map_public_ip_on_launch=false)│
  │   - Public Application Load Balancer (ALB)                            │
  │   - Managed NAT Gateways (1 per AZ for HA, or single for Dev)         │
  └─────────────────┬─────────────────────────────────┬───────────────────┘
                    │                                 │
           (Inbound Traffic)                (Outbound Egress via NAT)
                    │                                 │
  ┌─────────────────▼─────────────────────────────────▼───────────────────┐
  │                     Private Application Subnets                       │
  │   - Compute workloads: EC2, ECS, EKS, Lambda VPC                      │
  │   - Zero direct public internet ingress                              │
  │   - Protected egress to internet through NAT Gateways                 │
  │   - Internal AWS access via VPC Endpoints (S3, DynamoDB, SSM)        │
  └─────────────────┬─────────────────────────────────────────────────────┘
                    │ (Only DB Port e.g., 5432 / 3306)
                    ▼
  ┌───────────────────────────────────────────────────────────────────────┐
  │                     Isolated Database Subnets                         │
  │   - RDS / Aurora / ElastiCache Data Tier                              │
  │   - Completely isolated: NO Internet Gateway route, NO NAT route      │
  │   - Ingress strictly permitted from Application Tier Security Group   │
  │   - Dedicated `aws_db_subnet_group` pre-configured                    │
  └───────────────────────────────────────────────────────────────────────┘
```

---

## 🛡️ Security & Hardening Controls

| Security Control | Implementation | Benefit |
| :--- | :--- | :--- |
| **CIS Benchmark 5.4** | `aws_default_security_group` emptied | Restricts default SG from having any inbound/outbound rules. Prevents accidental exposure if resources are launched without specifying an SG. |
| **VPC Flow Logs** | CloudWatch Logs with custom IAM Role | Captures `ALL` traffic (ACCEPT and REJECT) with TCP flags for forensic auditing and automated threat analysis (GuardDuty). |
| **Gateway Endpoints** | S3 & DynamoDB VPC Endpoints | Direct routing across AWS internal backbone. Saves NAT data processing fees and ensures data never traverses public routes. |
| **Interface Endpoints** | AWS Systems Manager (SSM) | Eliminates SSH key management and port 22 exposure. Administrators connect via AWS SSM Session Manager inside private subnets. |
| **Stateless Layer (NACLs)** | Tier-specific Network ACLs | Subnet boundary filtering that isolates database subnets to only accept connections from application CIDRs on the database port. |
| **Stateful Layer (SGs)** | Least-privilege chained SGs | Internet ➜ ALB SG (80/443) ➜ App SG (8080/443) ➜ DB SG (5432/3306). |
| **Public IP Prevention** | `map_public_ip_on_launch = false` | Ensures newly launched EC2/ENI instances never automatically inherit public IPv4 addresses. |

---

## 📁 Repository Structure

```
.
├── main.tf                    # Root module invocation
├── variables.tf               # Root input parameters & configurable settings
├── outputs.tf                 # Exported VPC IDs, Subnet IDs, Security Groups
├── versions.tf                # Terraform & AWS provider constraints
├── terraform.tfvars.example   # Sample variable definitions
├── .gitignore                 # Excludes local state, secrets, and cache
└── modules/
    └── secure-vpc/
        ├── main.tf            # VPC, Subnets, IGW, NAT GWs, Route Tables, DB Subnet Group
        ├── flow_logs.tf       # VPC Flow Logs & CloudWatch IAM Policies
        ├── endpoints.tf       # S3/DynamoDB Gateway endpoints & SSM Interface endpoints
        ├── security_groups.tf # CIS default SG wipe & tiered security groups
        ├── nacls.tf           # Layered Network Access Control Lists (NACLs)
        ├── variables.tf       # Module variable inputs & validations
        └── outputs.tf         # Module outputs
```

---

## 🚀 Getting Started & Deployment

### 1. Prerequisites

Ensure you have **Terraform** and the **AWS CLI** installed on your machine.

If you are using macOS (Homebrew):
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
brew install awscli
```

Configure your AWS credentials:
```bash
aws configure
```

### 2. Configure Variables

Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your target AWS region, CIDR, and settings:
- For **Production**: Keep `single_nat_gateway = false` for high availability across AZs.
- For **Staging/Dev**: Set `single_nat_gateway = true` to save NAT Gateway hourly costs.

### 3. Initialize & Deploy

```bash
# 1. Initialize Terraform plugins
terraform init

# 2. Preview the execution plan
terraform plan

# 3. Apply the infrastructure
terraform apply
```

### 4. Teardown / Destroy

When no longer needed:
```bash
terraform destroy
```
# Secure-Cloud-Network
