#!/bin/bash

echo "=== Zero Trust Alertmanager Configuration ==="
echo "This script will help you configure notification channels for alerts."
echo ""

# Backup original config
cp alertmanager.yml alertmanager.yml.backup

echo "1. Email Configuration (Gmail)"
read -p "Enter your Gmail address: " email_address
read -p "Enter your Gmail app password: " email_password
read -p "Enter admin email for critical alerts: " admin_email
read -p "Enter security team email: " security_email

echo ""
echo "2. Slack Configuration"
read -p "Enter Slack webhook URL for general alerts: " slack_webhook
read -p "Enter Slack webhook URL for security alerts: " security_slack_webhook

# Update the configuration
sed -i "s/alerts@zerotrust-poc.com/$email_address/g" alertmanager.yml
sed -i "s/your-app-password/$email_password/g" alertmanager.yml
sed -i "s/admin@zerotrust-poc.com/$admin_email/g" alertmanager.yml
sed -i "s/security@zerotrust-poc.com/$security_email/g" alertmanager.yml
sed -i "s|https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK|$slack_webhook|g" alertmanager.yml
sed -i "s|https://hooks.slack.com/services/YOUR/SECURITY/WEBHOOK|$security_slack_webhook|g" alertmanager.yml

echo ""
echo "Configuration updated successfully!"
echo "Backup saved as alertmanager.yml.backup"
echo ""
echo "To apply changes, restart the monitoring stack:"
echo "docker-compose restart alertmanager"
echo ""
echo "Test your configuration at: http://localhost:9093" 