#!/bin/bash
set -e
exec > >(tee -a /var/log/user-data.log) 2>&1

echo "=========================================="
echo "User Data Started: $(date)"
echo "Phase 8: ASG + ALB + Auto Scaling"
echo "=========================================="

APP_DIR="/opt/csye6225"
cd "$APP_DIR"

# Append RDS configuration to existing .env
echo "" >> .env
echo "# RDS Database Configuration" >> .env
echo "DATABASE_HOST=${db_host}" >> .env
echo "DATABASE_PORT=5432" >> .env
echo "DATABASE_NAME=${db_name}" >> .env
echo "DATABASE_USER=${db_username}" >> .env
echo "DATABASE_PASSWORD=${db_password}" >> .env
echo "DATABASE_URL=postgresql://${db_username}:${db_password}@${db_host}:5432/${db_name}" >> .env

# Append S3 configuration
echo "" >> .env
echo "# S3 Configuration" >> .env
echo "S3_BUCKET_NAME=${s3_bucket}" >> .env
echo "AWS_REGION=${region}" >> .env
echo "ENVIRONMENT=${environment}" >> .env

# Set correct ownership and permissions
chown csye6225:csye6225 .env
chmod 600 .env

echo ""
echo "=== Updated .env file ==="
cat .env

# ========================================================================
# Configure and Restart CloudWatch Agent
# ========================================================================
echo ""
echo "=== Configuring CloudWatch Agent ==="

CLOUDWATCH_CONFIG="/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"

# Update log group name for environment
sudo sed -i "s/csye6225-webapp-dev/csye6225-webapp-${environment}/g" "$CLOUDWATCH_CONFIG"

echo "Updated CloudWatch config for environment: ${environment}"

# Restart CloudWatch Agent
echo "=== Restarting CloudWatch Agent ==="
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:$CLOUDWATCH_CONFIG

# Verify CloudWatch Agent is running
if systemctl is-active --quiet amazon-cloudwatch-agent; then
  echo "✓ CloudWatch Agent is running"
  sudo systemctl status amazon-cloudwatch-agent.service --no-pager
else
  echo "✗ CloudWatch Agent failed to start"
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
  echo "✓ Application is running"
  systemctl status webapp.service --no-pager
else
  echo "✗ Application failed to start"
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
  echo "✓ Health check passed"
else
  echo ""
  echo "✗ Health check failed"
fi

echo ""
echo "=========================================="
echo "User Data Completed: $(date)"
echo "=========================================="