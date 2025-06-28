# Zero Trust Monitoring Stack

This directory contains the monitoring and observability components for the Zero Trust Architecture PoC.

## Components

### Grafana Dashboards

Two comprehensive dashboards are automatically provisioned:

1. **Zero Trust Infrastructure Dashboard** (`grafana-dashboard.json`)
   - Service health overview
   - HTTP request rates and response times
   - Authentication and authorization failures
   - Rate limiting events
   - Database operations
   - System resource utilization
   - Error rates by service

2. **Zero Trust Security Dashboard** (`grafana-dashboard-security.json`)
   - Authentication success rates
   - Failed login attempts
   - Authorization decisions (OPA)
   - Policy evaluation times
   - JWT token validations
   - Rate limiting by IP
   - Suspicious activity monitoring
   - Certificate expiry tracking
   - Security events timeline

### Alertmanager

Configured with multiple notification channels:

- **Slack**: General alerts to `#alerts` channel
- **Email**: Critical alerts to admin team
- **Security Team**: Dedicated security alerts via email and Slack

#### Alert Routing

- Critical alerts → Email + Slack
- High error rates → Email + Slack
- Authentication failures → Security team (email + Slack)
- All other alerts → Slack only

#### Configuration

Update the following in `alertmanager.yml`:
- SMTP credentials for email notifications
- Slack webhook URLs
- Email addresses for different teams

### Prometheus

Collects metrics from:
- Kong API Gateway
- Backend Service
- OPA Policy Engine
- Keycloak Identity Provider
- Node Exporter (system metrics)

### Node Exporter

Provides system-level metrics:
- CPU and memory usage
- Disk I/O and space
- Network statistics
- Process information

## Setup Instructions

1. **Configure Notification Channels**:
   ```bash
   # Edit alertmanager.yml
   vim monitoring/alertmanager.yml
   
   # Update SMTP settings
   smtp_auth_username: 'your-email@gmail.com'
   smtp_auth_password: 'your-app-password'
   
   # Update Slack webhooks
   api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
   ```

2. **Deploy the Stack**:
   ```bash
   ./deploy.sh
   ```

3. **Access Dashboards**:
   - Grafana: http://localhost:3001 (admin/admin)
   - Prometheus: http://localhost:9090
   - Alertmanager: http://localhost:9093
   - Kibana: http://localhost:5601

## Dashboard Features

### Infrastructure Dashboard
- **Service Health**: Real-time status of all services
- **Performance Metrics**: Request rates, response times, error rates
- **Resource Monitoring**: CPU, memory, disk usage
- **Security Events**: Authentication/authorization failures

### Security Dashboard
- **Authentication Analytics**: Success rates, failure reasons
- **Authorization Monitoring**: OPA decision tracking
- **Token Management**: JWT validation statistics
- **Threat Detection**: Suspicious activity patterns
- **Certificate Management**: SSL certificate expiry tracking

## Alert Rules

The following alerts are configured:

- **Service Down**: When any service becomes unavailable
- **High Error Rate**: When error rate exceeds 5%
- **High Response Time**: When 95th percentile exceeds 2 seconds
- **Authentication Failures**: When auth failure rate is high
- **Certificate Expiry**: When SSL certificates expire soon
- **High CPU/Memory**: When system resources are stressed

## Customization

### Adding New Dashboards
1. Create dashboard JSON file
2. Add to `grafana/dashboards.yml` provisioning
3. Mount in docker-compose.yml

### Adding New Alerts
1. Add alert rules to `alerts.yml`
2. Configure routing in `alertmanager.yml`
3. Add notification channels as needed

### Custom Metrics
1. Instrument your services with Prometheus metrics
2. Add scrape configuration to `prometheus.yml`
3. Create dashboard panels for new metrics

## Troubleshooting

### Dashboard Not Loading
- Check Grafana logs: `docker-compose logs grafana`
- Verify dashboard JSON syntax
- Ensure Prometheus datasource is configured

### Alerts Not Firing
- Check Prometheus targets: http://localhost:9090/targets
- Verify alert rules: http://localhost:9090/alerts
- Check Alertmanager configuration: http://localhost:9093

### Notification Issues
- Verify SMTP/Slack credentials in `alertmanager.yml`
- Check Alertmanager logs: `docker-compose logs alertmanager`
- Test notification channels via Alertmanager UI 