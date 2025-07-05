# Zero Trust Architecture Proof of Concept

A comprehensive Zero Trust Architecture demonstration with advanced monitoring, security controls, and traffic simulation capabilities.

## Architecture Overview

This Zero Trust PoC demonstrates a secure, monitored architecture with the following components:

### Core Services

- **Keycloak** (Port 8080): Identity and Access Management
- **Express Gateway** (Port 8000): API Gateway with Zero Trust policies
- **Backend Service** (Port 4000): Business logic and data management
- **PostgreSQL**: Data persistence

### Security & Policy

- **OPA** (Port 8181): Policy engine for authorization decisions
- **Zero Trust Policies**: Rego-based security policies

### Monitoring Stack

- **Prometheus** (Port 9090): Metrics collection and storage
- **Grafana** (Port 3001): Advanced monitoring dashboards
- **AlertManager** (Port 9093): Alert management and notifications
- **Node Exporter** (Port 9100): System metrics collection
- **Elasticsearch** (Port 9200): Log storage and indexing
- **Kibana** (Port 5601): Log analysis and visualization
- **Logstash** (Port 5044): Log processing and forwarding

## Quick Start

### 1. Setup Networks

```bash
./scripts/setup-networks.sh
```

### 2. Generate Certificates

```bash
./scripts/generate-certs.sh
```

### 3. Deploy Services

```bash
./scripts/deploy.sh
```

### 4. Setup Users and Traffic Simulation

```bash
# Create users (1 admin + 10 normal users)
./scripts/setup-keycloak.sh

# Test traffic simulation
./scripts/test-traffic-simulation.sh
```

### 5. Generate Traffic for Monitoring

```bash
# Run mixed traffic for 10 minutes
./scripts/simulate-traffic.sh --type mixed --duration 600 --intensity normal

# Run malicious traffic for testing security
./scripts/simulate-traffic.sh --type malicious --duration 300 --intensity high
```

## Access Points

### Monitoring Dashboards

- **Grafana**: http://localhost:3001 (admin/admin)
  - Zero Trust Security Dashboard
  - System Performance Dashboard
  - Node Exporter Dashboard
- **Prometheus**: http://localhost:9090
- **Kibana**: http://localhost:5601

### API Access

- **Express Gateway**: http://localhost:8000
- **Backend Service**: http://localhost:4000
- **Keycloak**: http://localhost:8080

## Traffic Simulation

The system includes comprehensive traffic simulation capabilities:

### Traffic Types

- **Benign**: Normal user activities and API calls
- **Malicious**: Attack attempts (SQL injection, XSS, unauthorized access)
- **Mixed**: Combination of benign and malicious traffic

### Usage Examples

```bash
# Quick test
./scripts/test-traffic-simulation.sh

# Normal operations
./scripts/simulate-traffic.sh --type benign --duration 600 --intensity normal

# Security testing
./scripts/simulate-traffic.sh --type malicious --duration 300 --intensity high

# Realistic environment
./scripts/simulate-traffic.sh --type mixed --duration 900 --intensity normal
```

## Monitoring Features

### Grafana Dashboards

- **Security Events**: Real-time security monitoring
- **Performance Metrics**: System and application performance
- **User Activity**: User behavior and access patterns
- **Error Tracking**: Error rates and types
- **Traffic Analysis**: Request patterns and trends

### Alerting

- High error rates
- Unusual traffic patterns
- Security violations
- System resource issues

## Security Features

### Zero Trust Principles

- **Identity Verification**: Keycloak-based authentication
- **Policy Enforcement**: OPA-based authorization
- **Continuous Monitoring**: Real-time security monitoring
- **Least Privilege**: Role-based access control

### Security Controls

- JWT token validation
- Rate limiting
- Input validation
- Audit logging
- Security event correlation

## Development

### Project Structure

```
├── services/
│   ├── api-gateway/          # Express Gateway
│   └── backend-service/      # Business logic
├── monitoring/               # Monitoring stack configs
├── policies/                 # OPA security policies
├── scripts/                  # Automation scripts
└── networks/                 # Docker network configs
```

### Key Scripts

- `scripts/setup-keycloak.sh`: User and realm setup
- `scripts/simulate-traffic.sh`: Traffic simulation
- `scripts/test-traffic-simulation.sh`: Quick validation
- `scripts/deploy.sh`: Full deployment

## Troubleshooting

### Common Issues

1. **Services not starting**: Check network setup and certificates
2. **Authentication failures**: Re-run user setup script
3. **No monitoring data**: Run traffic simulation scripts
4. **Port conflicts**: Ensure ports are available

### Debug Commands

```bash
# Check service health
docker-compose ps

# View logs
docker-compose logs -f [service-name]

# Test API access
curl http://localhost:8000/health
curl http://localhost:4000/health
```

## Architecture Benefits

### Simplified Design

- **No Frontend Complexity**: Focus on monitoring and security
- **Direct API Access**: Traffic simulation directly tests the API
- **Monitoring-Centric**: Grafana as the primary interface
- **Reduced Attack Surface**: Fewer components to secure

### Enhanced Monitoring

- **Real-time Metrics**: Prometheus + Grafana
- **Security Events**: Comprehensive security monitoring
- **Performance Tracking**: System and application metrics
- **Log Analysis**: ELK stack for log processing

### Zero Trust Validation

- **Policy Enforcement**: OPA-based security policies
- **Identity Management**: Keycloak authentication
- **Continuous Monitoring**: Real-time security validation
- **Traffic Analysis**: Behavioral analysis and anomaly detection

This architecture provides a robust foundation for Zero Trust principles with comprehensive monitoring and security controls.
