# AWS Infrastructure with Terraform

Infrastructure as Code for CSYE6225 Cloud Computing - Assignment 5. This repository provisions AWS infrastructure including VPC, subnets, security groups, and EC2 instances using custom AMIs.

## Overview

This Terraform configuration deploys a complete web application infrastructure across two AWS accounts:
- **Dev Account**: Development environment for testing
- **Demo Account**: Production-like environment for demos

The EC2 instances use custom AMIs built with Packer (separate repository) that include a pre-configured FastAPI application with PostgreSQL.

## Prerequisites

- **Terraform** >= 1.0 ([Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli))
- **AWS CLI** configured with profiles for both accounts
- **Two AWS Accounts**: Dev (043310666846) and Demo (126588786406)
- **Custom AMI**: Built using Packer and shared between accounts
- **EC2 Key Pairs**: Created in both AWS accounts

## AWS Profile Setup

Configure AWS CLI profiles for both accounts:

### 1. Edit AWS Credentials File

**Windows**: `C:\Users\YourUsername\.aws\credentials`  
**Linux/Mac**: `~/.aws/credentials`

```ini
[dev]
aws_access_key_id = YOUR_DEV_ACCESS_KEY
aws_secret_access_key = YOUR_DEV_SECRET_KEY

[demo]
aws_access_key_id = YOUR_DEMO_ACCESS_KEY
aws_secret_access_key = YOUR_DEMO_SECRET_KEY
```

### 2. Edit AWS Config File

**Windows**: `C:\Users\YourUsername\.aws\config`  
**Linux/Mac**: `~/.aws/config`

```ini
[profile dev]
region = us-east-1
output = json

[profile demo]
region = us-east-1
output = json
```

### 3. Verify Profile Setup

```bash
# Test dev profile
aws sts get-caller-identity --profile dev

# Test demo profile
aws sts get-caller-identity --profile demo
```

## EC2 Key Pair Setup

Create SSH key pairs in both AWS accounts (key pairs cannot be shared between accounts):

```bash
# Create key pair in dev account
aws ec2 create-key-pair --key-name csye6225-dev --profile dev \
  --query 'KeyMaterial' --output text > csye6225-dev.pem

# Create key pair in demo account
aws ec2 create-key-pair --key-name csye6225-demo --profile demo \
  --query 'KeyMaterial' --output text > csye6225-demo.pem

# Set proper permissions (Linux/Mac)
chmod 400 csye6225-dev.pem
chmod 400 csye6225-demo.pem
```

**Windows (PowerShell)**:
```powershell
# Set file permissions
icacls csye6225-dev.pem /inheritance:r
icacls csye6225-dev.pem /grant:r "$($env:USERNAME):(R)"
```

## Infrastructure Components

This configuration creates:

- **VPC** (10.0.0.0/16)
- **3 Public Subnets** across 3 availability zones
- **3 Private Subnets** across 3 availability zones
- **Internet Gateway** with public route
- **Security Group** with ports: 22 (SSH), 80 (HTTP), 443 (HTTPS), 8000 (App)
- **EC2 Instance** (t2.micro) with custom AMI and 25GB encrypted EBS volume

## Quick Start

### Deploy to Dev Account

```bash
# 1. Initialize Terraform
terraform init

# 2. Validate configuration
terraform validate

# 3. Plan deployment
terraform plan -var-file="dev.tfvars"

# 4. Apply configuration
terraform apply -var-file="dev.tfvars"

# 5. View outputs
terraform output
```

### Deploy to Demo Account

```bash
# Plan deployment to demo account
terraform plan -var-file="demo.tfvars"

# Apply configuration
terraform apply -var-file="demo.tfvars"
```

### Destroy Infrastructure

```bash
# Destroy dev environment
terraform destroy -var-file="dev.tfvars"

# Destroy demo environment
terraform destroy -var-file="demo.tfvars"
```

## Configuration Files

### dev.tfvars
- AWS Profile: `dev`
- VPC Name: `csye6225-malav-dev`
- Key Pair: `csye6225-dev`
- AMI Owner: Dev account (043310666846)

### demo.tfvars
- AWS Profile: `demo`
- VPC Name: `csye6225-malav-demo`
- Key Pair: `csye6225-demo`
- AMI Owner: Dev account (043310666846) - shared AMI

## Custom AMI Details

- **Built with**: Packer (separate repository)
- **Base Image**: Ubuntu 24.04 LTS
- **Pre-installed**: FastAPI application, PostgreSQL, systemd service
- **Ownership**: Created in dev account, shared with demo account
- **Auto-start**: Application starts automatically via systemd

The AMI is owned by the dev account but shared with the demo account. Both accounts use the same `ami_owner_id` in their tfvars files because AMI ownership doesn't change when shared.

## Accessing the Application

After deployment, get the instance details:

```bash
# Get application URL
terraform output application_endpoints

# SSH into instance (dev)
ssh -i csye6225-dev.pem root@<public-ip>

# SSH into instance (demo)
ssh -i csye6225-demo.pem root@<public-ip>

# Test application
curl http://<public-ip>:8000/healthz
```


## CI/CD

GitHub Actions workflow runs on pull requests:
-  `terraform fmt -check` - Code formatting
-  `terraform init -backend=false` - Initialize without backend
-  `terraform validate` - Configuration validation

## Troubleshooting

### Issue: Credentials Not Found

```bash
# Set AWS profile environment variable
export AWS_PROFILE=dev           # Linux/Mac
$env:AWS_PROFILE = "dev"         # Windows PowerShell
```

### Issue: Key Pair Not Found

Ensure you've created the key pair in the correct AWS account:
```bash
aws ec2 describe-key-pairs --profile dev
aws ec2 describe-key-pairs --profile demo
```

### Issue: AMI Not Found

Verify the AMI is shared with the demo account:
```bash
# In dev account
aws ec2 describe-images --owners 043310666846 --filters "Name=name,Values=csye6225-*" --profile dev

# In demo account (should see same AMI)
aws ec2 describe-images --owners 043310666846 --filters "Name=name,Values=csye6225-*" --profile demo
```

### Issue: Terraform Destroy Fails

If `terraform destroy` doesn't remove resources:
```bash
# Restore state from backup
cp terraform.tfstate.backup terraform.tfstate

# Try destroy again
terraform destroy -var-file="demo.tfvars"
```

## Important Notes

- **State Files**: Not committed to git (`.gitignore`). Each deployment maintains its own state.
- **AMI Sharing**: AMI is always owned by dev account, even when used in demo account.
- **Key Pairs**: Cannot be shared between accounts; must create separately in each account.
- **Application**: Starts automatically on instance boot via systemd service.



## License

This project is part of CSYE6225 coursework - Assignment 5.

---

**Author**: Malav  
**Course**: CSYE6225 - Cloud Computing  
**Assignment**: Assignment 5 - Infrastructure as Code