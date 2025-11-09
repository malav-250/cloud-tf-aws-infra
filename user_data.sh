#!/bin/bash
set -e
exec > >(tee -a /var/log/user-data.log) 2>&1

echo "=========================================="
echo "User Data Started: $(date)"
echo "Phase 9: Using Secrets Manager"
echo "=========================================="

APP_DIR="/opt/csye6225"
cd "$APP_DIR"

# ============================================================================
# RETRIEVE SECRETS FROM AWS SECRETS MANAGER
# ============================================================================
echo ""
echo "=== Retrieving Secrets from Secrets Manager ==="

# Set AWS region for CLI
export AWS_DEFAULT_REGION=${region}

# Retrieve RDS credentials from Secrets Manager
echo "📦 Fetching database credentials..."
DB_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id csye6225-db-password-${environment} \
  --query SecretString \
  --output text)

if [ $? -ne 0 ]; then
  echo "❌ Failed to retrieve database credentials from Secrets Manager"
  exit 1
fi

# Parse JSON secret (using Python to properly decode JSON escape sequences)
echo "Parsing database credentials..."
DB_HOST=$(echo "$DB_SECRET" | python3 -c "import sys, json; print(json.load(sys.stdin)['host'])")
DB_PORT=$(echo "$DB_SECRET" | python3 -c "import sys, json; print(json.load(sys.stdin)['port'])")
DB_NAME=$(echo "$DB_SECRET" | python3 -c "import sys, json; print(json.load(sys.stdin)['dbname'])")
DB_USER=$(echo "$DB_SECRET" | python3 -c "import sys, json; print(json.load(sys.stdin)['username'])")
DB_PASSWORD=$(echo "$DB_SECRET" | python3 -c "import sys, json; print(json.load(sys.stdin)['password'])")

echo "✅ Database credentials retrieved successfully"
echo "   Host: $DB_HOST"
echo "   Database: $DB_NAME"
echo "   User: $DB_USER"

# Retrieve SendGrid API key from Secrets Manager
echo ""
echo "📧 Fetching SendGrid API key..."
SENDGRID_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id csye6225-sendgrid-key-${environment} \
  --query SecretString \
  --output text)

if [ $? -ne 0 ]; then
  echo "❌ Failed to retrieve SendGrid credentials from Secrets Manager"
  exit 1
fi

# Parse SendGrid secret (using Python)
SENDGRID_API_KEY=$(echo "$SENDGRID_SECRET" | python3 -c "import sys, json; print(json.load(sys.stdin)['api_key'])")
SENDGRID_FROM_EMAIL=$(echo "$SENDGRID_SECRET" | python3 -c "import sys, json; print(json.load(sys.stdin)['from_email'])")
SENDGRID_FROM_NAME=$(echo "$SENDGRID_SECRET" | python3 -c "import sys, json; print(json.load(sys.stdin)['from_name'])")

echo "✅ SendGrid credentials retrieved successfully"
echo "   From Email: $SENDGRID_FROM_EMAIL"
echo "   From Name: $SENDGRID_FROM_NAME"

# ============================================================================
# CREATE/UPDATE .ENV FILE
# ============================================================================
echo ""
echo "=== Updating .env file with retrieved secrets ==="

# Append RDS configuration to existing .env
echo "" >> .env
echo "# RDS Database Configuration (from Secrets Manager)" >> .env
echo "DATABASE_HOST=$DB_HOST" >> .env
echo "DATABASE_PORT=$DB_PORT" >> .env
echo "DATABASE_NAME=$DB_NAME" >> .env
echo "DATABASE_USER=$DB_USER" >> .env
echo "DATABASE_PASSWORD=$DB_PASSWORD" >> .env
echo "DATABASE_SSL_MODE=require" >> .env
echo "DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME" >> .env

# Append S3 configuration
echo "" >> .env
echo "# S3 Configuration" >> .env
echo "S3_BUCKET_NAME=${s3_bucket}" >> .env
echo "AWS_REGION=${region}" >> .env
echo "ENVIRONMENT=${environment}" >> .env

# Append SendGrid configuration
echo "" >> .env
echo "# SendGrid Configuration (from Secrets Manager)" >> .env
echo "SENDGRID_API_KEY=$SENDGRID_API_KEY" >> .env
echo "SENDGRID_FROM_EMAIL=$SENDGRID_FROM_EMAIL" >> .env
echo "SENDGRID_FROM_NAME=$SENDGRID_FROM_NAME" >> .env

# Set correct ownership and permissions
chown csye6225:csye6225 .env
chmod 600 .env

echo "✅ .env file updated successfully"

# ========================================================================
# Configure and Restart CloudWatch Agent
# ========================================================================
echo ""
echo "=== Configuring CloudWatch Agent ==="

CLOUDWATCH_CONFIG="/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"

# Update log group name for environment
sudo sed -i "s/csye6225-webapp-dev/csye6225-webapp-${environment}/g" "$CLOUDWATCH_CONFIG"

echo "✅ Updated CloudWatch config for environment: ${environment}"

# Restart CloudWatch Agent
echo "=== Restarting CloudWatch Agent ==="
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:$CLOUDWATCH_CONFIG

# Verify CloudWatch Agent is running
if systemctl is-active --quiet amazon-cloudwatch-agent; then
  echo "✅ CloudWatch Agent is running"
else
  echo "❌ CloudWatch Agent failed to start"
  sudo systemctl status amazon-cloudwatch-agent.service --no-pager
fi

# ========================================================================
# Restart Application
# ========================================================================
echo ""
echo "=== Restarting webapp service ==="
systemctl daemon-reload
systemctl enable webapp.service
systemctl restart webapp.service

# Wait for service to start
sleep 5

# Check application status
if systemctl is-active --quiet webapp.service; then
  echo "✅ Application is running"
  systemctl status webapp.service --no-pager
else
  echo "❌ Application failed to start"
  systemctl status webapp.service --no-pager
  echo ""
  echo "=== Application logs ==="
  journalctl -u webapp.service -n 50 --no-pager
  exit 1
fi

# Test health endpoint
echo ""
echo "=== Testing health endpoint ==="
sleep 5
if curl -f http://localhost:8000/healthz; then
  echo ""
  echo "✅ Health check passed"
else
  echo ""
  echo "❌ Health check failed"
fi

echo ""
echo "=========================================="
echo "User Data Completed: $(date)"
echo "=========================================="