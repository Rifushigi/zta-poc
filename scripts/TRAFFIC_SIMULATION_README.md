# Traffic Simulation Scripts

This directory contains scripts for simulating diverse traffic patterns to test the Zero Trust Architecture monitoring and security systems.

## Overview

The traffic simulation system consists of:

1. **`simulate-traffic.sh`** - Main traffic simulation script
2. **`test-traffic-simulation.sh`** - Test script for quick validation
3. **Updated `setup-keycloak.sh`** - Creates 10 normal users + 1 admin user

## Architecture Notes

This system operates without a frontend, focusing on:

- **Direct API Testing**: Traffic simulation directly tests the Express Gateway and Backend APIs
- **Monitoring-Centric**: Grafana serves as the primary interface for system monitoring
- **Security Validation**: Comprehensive testing of Zero Trust policies and security controls

## Features

### Traffic Types

- **Benign Traffic**: Normal user activities like browsing data, creating items, health checks
- **Malicious Traffic**: Attack attempts including SQL injection, XSS, path traversal, unauthorized access
- **Mixed Traffic**: Combination of 70% benign and 30% malicious traffic

### Intensity Levels

- **Low**: 5-15 seconds between requests
- **Normal**: 2-7 seconds between requests
- **High**: 1-4 seconds between requests

### User Management

The system creates 11 users total:

- **1 Admin**: `admin/adminpass` (admin role)
- **10 Normal Users**: `user1/user1pass` through `user10/user10pass` (user roles)

## Usage

### Basic Usage

```bash
# Run benign traffic for 5 minutes
./scripts/simulate-traffic.sh --type benign --duration 300

# Run malicious traffic for 2 minutes with high intensity
./scripts/simulate-traffic.sh --type malicious --duration 120 --intensity high

# Run mixed traffic for 10 minutes
./scripts/simulate-traffic.sh --type mixed --duration 600
```

### Advanced Usage

```bash
# Custom users file and log location
./scripts/simulate-traffic.sh \
  --type mixed \
  --duration 900 \
  --intensity normal \
  --users /path/to/custom/users.json \
  --log /path/to/custom/log.log

# Quick test run
./scripts/test-traffic-simulation.sh
```

### Command Line Options

| Option            | Description                            | Default                     |
| ----------------- | -------------------------------------- | --------------------------- |
| `-t, --type`      | Traffic type: benign, malicious, mixed | benign                      |
| `-d, --duration`  | Duration in seconds                    | 300                         |
| `-i, --intensity` | Intensity: low, normal, high           | normal                      |
| `-u, --users`     | Users file path                        | /tmp/simulation_users.json  |
| `-l, --log`       | Log file path                          | /tmp/traffic_simulation.log |
| `-h, --help`      | Show help message                      | -                           |

## Traffic Patterns

### Benign Traffic Includes

- **GET Requests**:

  - `/api/data` - Browse user's data
  - `/api/data?page=1&limit=5` - Paginated data access
  - `/health` - Health check
  - `/metrics` - Metrics endpoint
  - `/api/admin` - Admin-only data (for admin users)

- **POST Requests**:
  - `/api/data` - Create new items with realistic names and descriptions

### Malicious Traffic Includes

- **SQL Injection Attempts**:

  - `?page=1' OR '1'='1`
  - `?page=1; DROP TABLE items;`
  - `?page=1 UNION SELECT * FROM users`

- **XSS Attempts**:

  - `<script>alert('xss')</script>`
  - `javascript:alert('xss')`

- **Path Traversal**:

  - `/api/data/../../../etc/passwd`
  - `/api/data/..\\..\\..\\windows\\system32\\config\\sam`

- **Unauthorized Access**:
  - Accessing `/api/admin` without admin role
  - Large payload attacks
  - Rate limiting bypass attempts

## Monitoring Integration

The traffic simulation generates data for all monitoring components:

### Prometheus Metrics

- HTTP request duration
- Request counts by method, route, and status code
- Database operation metrics
- Rate limiting events

### Grafana Dashboards

- Request patterns over time
- Error rates and types
- User activity patterns
- Security event detection

### Log Analysis

- Structured logging with request IDs
- User activity tracking
- Security event logging
- Performance metrics

## Files Generated

### Users File (`/tmp/simulation_users.json`)

```json
{
  "users": [
    "admin:adminpass",
    "user1:user1pass",
    "user2:user2pass",
    ...
    "user10:user10pass"
  ]
}
```

### Log File (`/tmp/traffic_simulation.log`)

```
2024-01-15 10:30:15 - BENIGN - user3 - GET /api/data - 200
2024-01-15 10:30:18 - MALICIOUS - user7 - GET /api/data?page=1' OR '1'='1 - 400
2024-01-15 10:30:21 - BENIGN - admin - GET /api/admin - 200
```

## Security Testing Scenarios

### 1. Normal Operations

```bash
./scripts/simulate-traffic.sh --type benign --duration 600 --intensity normal
```

Tests normal user behavior and system performance.

### 2. Attack Simulation

```bash
./scripts/simulate-traffic.sh --type malicious --duration 300 --intensity high
```

Tests security controls and alerting systems.

### 3. Mixed Environment

```bash
./scripts/simulate-traffic.sh --type mixed --duration 900 --intensity normal
```

Simulates realistic environment with both normal and malicious traffic.

## Dependencies

Required system tools:

- `curl` - HTTP requests
- `jq` - JSON parsing
- `uuidgen` - Request ID generation
- `bc` - Mathematical calculations

## Troubleshooting

### Common Issues

1. **Services not running**:

   ```bash
   # Check if services are available
   curl http://localhost:8080/health  # Keycloak
   curl http://localhost:4000/health  # Backend
   ```

2. **Authentication failures**:

   ```bash
   # Re-run user setup
   ./scripts/setup-keycloak.sh
   ```

3. **Permission denied**:
   ```bash
   # Make scripts executable
   chmod +x scripts/simulate-traffic.sh
   chmod +x scripts/test-traffic-simulation.sh
   ```

### Debug Mode

To see detailed output, modify the script to add `set -x` at the beginning for debug mode.

## Integration with Monitoring Stack

The traffic simulation works with all monitoring components:

- **Prometheus**: Collects metrics from backend service
- **Grafana**: Visualizes traffic patterns and security events
- **AlertManager**: Triggers alerts on suspicious activity
- **Logstash**: Processes structured logs
- **Elasticsearch**: Stores and indexes log data
- **Kibana**: Provides log analysis interface

## Performance Considerations

- **Low intensity**: Suitable for development and testing
- **Normal intensity**: Good for most monitoring scenarios
- **High intensity**: Use for stress testing and performance validation

## Customization

### Adding New Traffic Patterns

Edit `simulate-traffic.sh` and add new patterns to the `malicious_actions` array:

```bash
local malicious_actions=(
    # Your new patterns here
    "GET:/api/data?custom=attack"
)
```

### Custom User Files

Create a custom users file:

```json
{
  "users": ["customuser1:password1", "customuser2:password2"]
}
```

Then use with `--users /path/to/custom/users.json`
