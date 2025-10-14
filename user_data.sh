#!/bin/bash
set -e

# Log user data execution
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting user data script execution at $(date)"

# Wait for cloud-init to complete
cloud-init status --wait

# Database configuration
DB_HOST="${db_host}"
DB_PORT="${db_port}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"

# Application configuration
APP_PORT="${app_port}"
APP_ENV="${app_env}"

# Create .env file for the application
cat > /opt/webapp/.env << EOF
# Database Configuration
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD

# Application Configuration
APP_PORT=$APP_PORT
APP_ENV=$APP_ENV
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME
EOF

# Set proper ownership and permissions
chown csye6225:csye6225 /opt/webapp/.env
chmod 600 /opt/webapp/.env

echo "Environment file created at /opt/webapp/.env"

# Restart the application service to pick up new configuration
systemctl restart webapp.service

# Wait a few seconds and check service status
sleep 5
systemctl status webapp.service

echo "User data script completed at $(date)"