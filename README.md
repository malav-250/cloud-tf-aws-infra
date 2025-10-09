# AWS Infrastructure with Terraform

Infrastructure as Code for CSYE6225 Cloud Computing course. This repository contains Terraform configurations to provision AWS networking infrastructure including VPC, subnets, Internet Gateway, and route tables.

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- AWS account with necessary permissions

## Infrastructure Components

This Terraform configuration creates:

- **VPC** with configurable CIDR block
- **Public Subnets** (default: 3) with auto-assigned public IPs
- **Private Subnets** (default: 3) without public IP assignment
- **Internet Gateway** attached to VPC
- **Public Route Table** with internet access (0.0.0.0/0 → IGW)
- **Private Route Table** for internal traffic only
- Resources distributed across multiple Availability Zones

## Configuration

### Using Environment-Specific Variable Files

The repository includes two pre-configured environments:

- `dev.tfvars` - Development environment for me
- `demo.tfvars` - Demonstration environment for TA reviews

### Quick Start

1. **Clone the repository**
```bash
git clone <repository-url>
cd tf-aws-infra
```

2. **Initialize Terraform**
```bash
terraform init
```

3. **Validate configuration**
```bash
terraform validate
```

4. **Plan deployment (Dev environment)**
```bash
terraform plan -var-file="dev.tfvars"
```

5. **Apply configuration**
```bash
terraform apply -var-file="dev.tfvars"
```

6. **Destroy infrastructure when done**
```bash
terraform destroy -var-file="dev.tfvars"
```

## Customization

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for deployment | `us-east-1` |
| `vpc_name` | Name prefix for VPC resources | Required |
| `vpc_cidr` | CIDR block for VPC | `10.0.0.0/16` |
| `environment` | Environment name (dev/demo/prod) | `dev` |
| `public_subnet_count` | Number of public subnets | `3` |
| `private_subnet_count` | Number of private subnets | `3` |
| `az_count` | Number of availability zones to use | `3` |

### Creating Custom Configurations

Copy the example file and modify:
```bash
cp terraform.tfvars.example terraform.tfvars
#edit terraform.tfvars with your values
terraform plan
```

## Multiple VPC Deployment

To create multiple VPCs in the same AWS account and region:

```bash
# First VPC
terraform apply -var-file="dev.tfvars"

# Second VPC (different workspace or state file)
terraform workspace new demo
terraform apply -var-file="demo.tfvars"
```

## Outputs

After successful deployment, Terraform outputs:

- VPC ID and CIDR block
- All subnet IDs, CIDRs, and availability zones
- Internet Gateway ID
- Route table IDs
- Infrastructure summary

View outputs:
```bash
terraform output
```

## CI/CD

GitHub Actions workflow automatically runs on pull requests:
- `terraform fmt -check` - Verifies code formatting
- `terraform validate` - Validates configuration syntax

## File Structure

```
.
├── .github/workflows/terraform-ci.yml     #ci yml
├── vpc.tf                  # VPC resource definition
├── subnets.tf             # Public and private subnet creation
├── internet_gateway.tf    # Internet Gateway configuration
├── route_tables.tf        # Route tables and associations
├── data.tf                # Data sources (AZs)
├── locals.tf              # Local computed values
├── variables.tf           # Input variable definitions
├── outputs.tf             # Output value definitions
├── providers.tf           # Provider configuration
├── versions.tf            # Version constraints
├── dev.tfvars            # Dev environment variables
├── demo.tfvars           # Demo environment variables
└── .gitignore            # Git ignore patterns
```


**Issue:** AWS credentials not found
```bash
#configure AWS CLI profile
aws configure --profile dev
$env:AWS_PROFILE="dev"

```

## License

This project is part of CSYE6225 coursework.
