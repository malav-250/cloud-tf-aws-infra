# AWS Infrastructure with Terraform

Infrastructure as Code for CSYE6225 Cloud Computing. This repository provisions complete AWS infrastructure including VPC, RDS PostgreSQL, S3 storage, Lambda functions, and Auto Scaling Groups.

## Overview

Terraform configuration for cloud-native web application infrastructure across two AWS accounts:
- **Dev Account (043310666846)**: Development and testing environment
- **Demo Account (126588786406)**: Production-like demonstration environment

## Infrastructure Components

- **VPC** (10.0.0.0/16) with public and private subnets across 3 AZs
- **Application Load Balancer** with SSL/TLS termination
- **Auto Scaling Group** with Launch Template
- **RDS PostgreSQL 16.4** (db.t3.micro) in private subnets
- **S3 Bucket** with versioning, encryption, lifecycle policies
- **Lambda Function** for email verification (triggered by SNS)
- **DynamoDB** for email verification tokens
- **SNS Topic** for user registration events
- **CloudWatch** alarms and monitoring
- **Security Groups** with least-privilege access
- **IAM Roles** for EC2 and Lambda

## Prerequisites

- **Terraform** >= 1.0 ([Install](https://developer.hashicorp.com/terraform/downloads))
- **AWS CLI** configured with profiles
- **Custom AMI** built using Packer
- **SSL Certificate** for demo environment (Namecheap)

## AWS Profile Setup

**`~/.aws/credentials`:**
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

## SSL Certificate Setup

### Dev Environment (AWS Certificate Manager)

Dev environment uses AWS Certificate Manager (ACM) for automatic certificate provisioning with DNS validation. No manual import needed - Terraform handles this automatically.

```bash
# Certificate is created automatically by Terraform
terraform apply -var-file="dev.tfvars"
```

### Demo Environment (Namecheap Certificate Import)

Demo environment requires importing an SSL certificate purchased from Namecheap into AWS Certificate Manager.

#### Prerequisites

1. Purchase SSL certificate from Namecheap for `demo.malavgajera.me`
2. Download certificate files from Namecheap:
   - Certificate file (`.crt`)
   - Private key (`.key`)
   - CA Bundle/Chain (`.ca-bundle`)

#### Import Certificate Command

**Import SSL certificate to AWS Certificate Manager:**

```bash
# Set AWS profile for demo account
export AWS_PROFILE=demo  # Linux/Mac
$env:AWS_PROFILE="demo"  # Windows PowerShell

# Import certificate
aws acm import-certificate \
  --certificate fileb://demo_malavgajera_me.crt \
  --private-key fileb://demo_malavgajera_me.key \
  --certificate-chain fileb://demo_malavgajera_me.ca-bundle \
  --region us-east-1 \
  --tags Key=Name,Value=demo.malavgajera.me Key=Environment,Value=demo
```

**Note the Certificate ARN from the output:**
```json
{
    "CertificateArn": "arn:aws:acm:us-east-1:126588786406:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

#### Update Terraform Configuration

After importing, update your `demo.tfvars` with the certificate ARN:

```hcl
# demo.tfvars
ssl_certificate_arn = "arn:aws:acm:us-east-1:126588786406:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

Then apply Terraform:

```bash
terraform apply -var-file="demo.tfvars"
```

#### Verify Certificate

```bash
# List certificates in ACM
aws acm list-certificates --region us-east-1 --profile demo

# Get certificate details
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:126588786406:certificate/YOUR-CERT-ID \
  --region us-east-1 \
  --profile demo
```

#### Certificate Renewal

Namecheap certificates must be manually renewed before expiration. When renewing:

1. Download new certificate files from Namecheap
2. Import new certificate using the same command above
3. Update Terraform with new certificate ARN
4. Run `terraform apply`
5. Delete old certificate from ACM

**Warning:** Do not delete the old certificate until the new one is imported and configured to avoid downtime.

## Quick Start

### Deploy to Dev Environment

```bash
# Initialize Terraform (first time only)
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -var-file="dev.tfvars"

# Apply configuration
terraform apply -var-file="dev.tfvars"

# View outputs
terraform output
```

### Deploy to Demo Environment

```bash
# Import SSL certificate first (see SSL Certificate Setup section above)
# Then deploy infrastructure
terraform plan -var-file="demo.tfvars"
terraform apply -var-file="demo.tfvars"
```

## Configuration Files

### dev.tfvars
```hcl
aws_profile  = "dev"
vpc_name     = "csye6225-malav-dev"
environment  = "dev"
ec2_key_name = "csye6225-dev"

# RDS Configuration
db_name     = "csye6225"
db_username = "csye6225"
db_password = "CSYE-6225"

# Cost optimization for dev
db_multi_az            = false
db_deletion_protection = false
```

### demo.tfvars
```hcl
aws_profile  = "demo"
vpc_name     = "csye6225-malav-demo"
environment  = "demo"
ec2_key_name = "csye6225-demo"

# RDS Configuration
db_name     = "csye6225"
db_username = "csye6225"
db_password = "CSYE-6225"

# SSL Certificate (imported from Namecheap)
ssl_certificate_arn = "arn:aws:acm:us-east-1:126588786406:certificate/YOUR-CERT-ID"
```

## Terraform Workspace Setup (Optional)

Use workspaces to maintain both dev and demo infrastructure simultaneously:

```bash
# Create workspaces
terraform workspace new dev
terraform workspace new demo

# Deploy to dev
terraform workspace select dev
export AWS_PROFILE=dev
terraform apply -var-file="dev.tfvars"

# Deploy to demo
terraform workspace select demo
export AWS_PROFILE=demo
terraform apply -var-file="demo.tfvars"

# Both environments now exist simultaneously!
```

## Access Application

```bash
# Dev environment
curl https://dev.malavgajera.me/healthz

# Demo environment
curl https://demo.malavgajera.me/healthz
```

## Important Outputs

```bash
# Networking
terraform output vpc_id
terraform output public_subnet_ids

# Load Balancer
terraform output alb_dns_name
terraform output application_url

# Auto Scaling
terraform output launch_template_id
terraform output autoscaling_group_name

# Database
terraform output rds_endpoint

# Storage
terraform output s3_bucket_name

# Lambda
terraform output lambda_function_arn
terraform output sns_topic_arn
```

## Verification Tests

```bash
# Health check
curl https://dev.malavgajera.me/healthz

# Create user (triggers email verification)
curl -X POST https://dev.malavgajera.me/v1/user \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Test",
    "last_name": "User",
    "username": "test@example.com",
    "password": "Test@1234"
  }'

# Check Lambda logs
aws logs tail /aws/lambda/csye6225-email-verification-dev \
  --follow --profile dev

# Verify DynamoDB token
aws dynamodb scan \
  --table-name email-verification-tokens-dev \
  --profile dev
```

## Cleanup

```bash
# Destroy dev environment
terraform destroy -var-file="dev.tfvars"

# Destroy demo environment
terraform destroy -var-file="demo.tfvars"
```

**Note**: S3 bucket and DynamoDB table must be empty before destroy.



## Cost Optimization

- **Dev**: Single AZ RDS, no deletion protection
- **Demo**: Can enable Multi-AZ for demos
- **Instance Types**: t2.micro / db.t3.micro
- **Auto Scaling**: Min 1, Max 3 instances

## Related Repositories

- **Webapp**: FastAPI application with Packer AMI configuration
- **Serverless**: Lambda function for email verification

---

**Course**: CSYE6225 - Cloud Computing  
**Student**: Malav Gajera  
**Institution**: Northeastern University