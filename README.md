# AWS Infrastructure with Terraform

Infrastructure as Code for CSYE6225 Cloud Computing - Assignment 6. This repository provisions complete AWS infrastructure including VPC, RDS PostgreSQL, S3 storage, and EC2 instances using custom AMIs.

## Overview

Terraform configuration that deploys cloud-native web application infrastructure across two AWS accounts:
- **Dev Account (043310666846)**: Development and testing environment
- **Demo Account (126588786406)**: Production-like demonstration environment

Key architectural principle: **Immutable Infrastructure** - AMI contains application only, all data services (RDS, S3) are external and managed by Terraform.

## Infrastructure Components

### Assignment 6 Architecture
- **VPC** (10.0.0.0/16) with public and private subnets across 3 AZs
- **RDS PostgreSQL 16.4** (db.t3.micro) in private subnets, NOT publicly accessible
- **S3 Bucket** with UUID-based naming, versioning, encryption, lifecycle policies
- **EC2 Instance** (t2.micro) with IAM role for S3 access, 25GB encrypted EBS
- **Security Groups** for application (public) and database (private)
- **IAM Role & Instance Profile** for secure S3 access (no hardcoded credentials)

### What Gets Created
```
AWS Infrastructure
├── Networking
│   ├── VPC (10.0.0.0/16)
│   ├── 3 Public Subnets (for EC2)
│   ├── 3 Private Subnets (for RDS)
│   ├── Internet Gateway
│   └── Route Tables
├── Security
│   ├── Application Security Group (SSH, HTTP, HTTPS, 8000)
│   ├── RDS Security Group (PostgreSQL 5432 from app only)
│   └── IAM Role + Instance Profile (S3 access)
├── Compute
│   └── EC2 Instance with Custom AMI
├── Database
│   ├── RDS PostgreSQL Instance
│   ├── DB Subnet Group (3 private subnets)
│   └── Custom Parameter Group
└── Storage
    └── S3 Bucket (webapp-images-{env}-{uuid})
```

## Prerequisites

- **Terraform** >= 1.0 ([Install](https://developer.hashicorp.com/terraform/downloads))
- **AWS CLI** configured with profiles for both accounts
- **Custom AMI**: Built using Packer from separate repository
- **EC2 Key Pairs**: Created in both AWS accounts (`csye6225-dev`, `csye6225-demo`)

## AWS Profile Setup

Configure AWS CLI with named profiles:

**`~/.aws/credentials` (Linux/Mac) or `C:\Users\{User}\.aws\credentials` (Windows):**
```ini
[dev]
aws_access_key_id = YOUR_DEV_ACCESS_KEY
aws_secret_access_key = YOUR_DEV_SECRET_KEY

[demo]
aws_access_key_id = YOUR_DEMO_ACCESS_KEY
aws_secret_access_key = YOUR_DEMO_SECRET_KEY
```

**`~/.aws/config`:**
```ini
[profile dev]
region = us-east-1
output = json

[profile demo]
region = us-east-1
output = json
```

**Verify:**
```bash
aws sts get-caller-identity --profile dev
aws sts get-caller-identity --profile demo
```

## Quick Start

### Deploy to Dev Environment

```bash
# Initialize Terraform (first time only)
terraform init

# Validate configuration
terraform validate

# Plan deployment (review changes)
terraform plan -var-file="dev.tfvars"

# Apply configuration
terraform apply -var-file="dev.tfvars"

# View outputs
terraform output
```

### Deploy to Demo Environment

```bash
terraform plan -var-file="demo.tfvars"
terraform apply -var-file="demo.tfvars"
```

### Access Application

```bash
# Get application URL
terraform output application_endpoints

# Test health check
curl http://$(terraform output -raw ec2_instance_public_ip):8000/healthz

# Get RDS endpoint
terraform output rds_endpoint

# Get S3 bucket name
terraform output s3_bucket_name
```

## Configuration Files

### dev.tfvars
```hcl
aws_profile = "dev"
vpc_name    = "csye6225-malav-dev"
environment = "dev"
ec2_key_name = "csye6225-dev"

# RDS Configuration
db_name     = "csye6225"
db_username = "csye6225"
db_password = "CSYE-6225"

# Cost optimization for dev
db_multi_az = false
db_deletion_protection = false
```

### demo.tfvars
```hcl
aws_profile = "demo"
vpc_name    = "csye6225-malav-demo"
environment = "demo"
ec2_key_name = "csye6225-demo"

# RDS Configuration (same credentials)
db_name     = "csye6225"
db_username = "csye6225"
db_password = "CSYE-6225"
```

## Key Features

### RDS Integration
- **External Database**: PostgreSQL runs on AWS RDS, not in EC2/AMI
- **Private Subnets**: Database isolated in private subnets across 3 AZs
- **Security**: Only application security group can access database
- **Backup**: 7-day retention with automated backups
- **Encryption**: Storage encryption enabled by default

### S3 Storage
- **Unique Naming**: UUID-based bucket names prevent collisions
- **Security**: All public access blocked, IAM role-based access only
- **Versioning**: Enabled for data protection
- **Encryption**: Server-side AES256 encryption
- **Lifecycle**: Transition to STANDARD_IA after 30 days, cleanup old versions

### IAM Security
- **No Hardcoded Credentials**: EC2 uses IAM instance profile for S3
- **Least Privilege**: Policy allows only necessary S3 operations
- **IMDSv2**: Secure instance metadata access

### Runtime Configuration
Application receives database and S3 configuration via user-data at launch:
```bash
# Terraform injects these at EC2 boot time
DATABASE_HOST=<rds-endpoint>
DATABASE_PORT=5432
DATABASE_NAME=csye6225
S3_BUCKET_NAME=webapp-images-dev-<uuid>
AWS_REGION=us-east-1
```


## Important Outputs

```bash
# Networking
terraform output vpc_id
terraform output public_subnet_ids
terraform output private_subnet_ids

# Compute
terraform output ec2_instance_id
terraform output ec2_instance_public_ip

# Database
terraform output rds_endpoint
terraform output rds_address
terraform output database_connection_string

# Storage
terraform output s3_bucket_name
terraform output s3_bucket_arn

# Security
terraform output iam_role_arn
terraform output iam_instance_profile_name
```

## Verification Tests

After deployment, run these verification commands:

```bash
# 1. Health Check
curl http://$(terraform output -raw ec2_instance_public_ip):8000/healthz

# 2. Verify S3 bucket security
aws s3api get-public-access-block \
  --bucket $(terraform output -raw s3_bucket_name) \
  --profile dev

# 3. Verify RDS is not publicly accessible
aws rds describe-db-instances \
  --db-instance-identifier csye6225 \
  --query 'DBInstances[0].PubliclyAccessible' \
  --profile dev

# 4. Test RDS connectivity (should timeout from local)
timeout 5 psql -h $(terraform output -raw rds_address) \
  -U csye6225 -d csye6225
```

## SSH Access & Manual Verification

```bash
# SSH to EC2 instance
ssh -i csye6225-dev.pem admin@$(terraform output -raw ec2_instance_public_ip)

# Install PostgreSQL client (for demo)
sudo apt-get update && sudo apt-get install -y postgresql-client

# Test RDS connectivity from EC2
psql -h $(terraform output -raw rds_address) -U csye6225 -d csye6225

# Verify environment configuration
sudo cat /opt/csye6225/.env | grep -v PASSWORD

# Check application logs
sudo journalctl -u webapp.service -n 50
```

## Cleanup

```bash
# Destroy dev environment
terraform destroy -var-file="dev.tfvars"

# Destroy demo environment
terraform destroy -var-file="demo.tfvars"
```

**Note**: S3 bucket must be empty before destroy. Set `force_destroy = true` in dev to auto-delete objects.

## CI/CD

GitHub Actions workflow validates on every PR:
- `terraform fmt -check` - Code formatting
- `terraform init -backend=false` - Initialize
- `terraform validate` - Configuration validation

## Cost Optimization

### Dev Environment
- Single AZ RDS (no Multi-AZ)
- No deletion protection
- t2.micro / db.t3.micro instances
- S3 force_destroy enabled

### Demo Environment
- Consider Multi-AZ for resilience demos
- Enable deletion protection
- Same instance sizes (demo != production)

## Troubleshooting

### AMI Not Found
```bash
# Verify AMI exists and is shared
aws ec2 describe-images --owners 043310666846 \
  --filters "Name=name,Values=csye6225-*" --profile demo
```

### RDS Connection Issues
- Check security group allows traffic from application SG
- Verify RDS is in private subnets
- Confirm user-data script completed successfully

### S3 Access Denied
- Verify IAM instance profile is attached to EC2
- Check IAM policy has correct S3 bucket ARN
- Ensure application uses IAM role, not access keys

## Related Repositories

- **Webapp Repository**: FastAPI application with Packer configuration
- **Custom AMI**: Built in webapp repo, shared to this infrastructure


**Course**: CSYE6225 - Cloud Computing  
**Student**: Malav  
**Assignment**: 6 - Cloud-Native Infrastructure with RDS and S3