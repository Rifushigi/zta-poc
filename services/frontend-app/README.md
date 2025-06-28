# Zero Trust Frontend Application

A modern React-based user interface for the Zero Trust Architecture Proof of Concept.

## Features

### 🔐 Authentication & Authorization
- **Keycloak Integration**: Seamless SSO with Keycloak
- **Role-Based Access**: Different views based on user roles
- **JWT Token Management**: Automatic token refresh and validation
- **Secure Logout**: Proper session cleanup

### 📊 Dashboard
- **User Overview**: Personal data and activity summary
- **Security Status**: Authentication and authorization metrics
- **System Health**: Service status indicators
- **Recent Activity**: Audit trail visualization

### 📝 Data Management
- **CRUD Operations**: Create, read, update, delete items
- **Role-Based Access**: Users can only access their own data
- **Real-time Updates**: Live data synchronization
- **Search & Filter**: Advanced data filtering capabilities

### 🔧 Admin Panel (Admin Only)
- **User Management**: View and manage all users
- **System Overview**: Comprehensive system metrics
- **Policy Management**: OPA policy configuration interface
- **Audit Logs**: Complete activity audit trail

### 🛡️ Security Overview (Admin/Security Roles)
- **Authentication Analytics**: Success/failure rates
- **Authorization Decisions**: OPA policy evaluation results
- **Threat Detection**: Suspicious activity monitoring
- **Certificate Management**: SSL certificate status

## Technology Stack

- **React 18**: Modern React with hooks
- **Material-UI**: Professional UI components
- **React Router**: Client-side routing
- **React Query**: Server state management
- **Keycloak JS**: Authentication client
- **Axios**: HTTP client with interceptors
- **Yup**: Form validation

## Security Features

- **HTTPS Only**: All communication over TLS
- **Security Headers**: CSP, HSTS, XSS protection
- **Rate Limiting**: API request throttling
- **Input Validation**: Client-side and server-side validation
- **Token Security**: Secure token storage and transmission

## Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build:prod
```

## Deployment

The frontend is containerized with nginx for production deployment:

```bash
# Build Docker image
docker build -t zero-trust-frontend .

# Run container
docker run -p 8080:443 zero-trust-frontend
```

## Integration

The frontend integrates with:
- **Backend API**: RESTful API for data operations
- **Keycloak**: Identity and access management
- **Kong Gateway**: API gateway with mTLS
- **OPA**: Policy enforcement engine

## Demo Scenarios

1. **User Authentication**: Login with different user roles
2. **Data Access Control**: See role-based data filtering
3. **Admin Functions**: Access admin-only features
4. **Security Monitoring**: View security metrics and alerts
5. **Policy Enforcement**: Test OPA policy decisions

This frontend provides a complete user experience for demonstrating Zero Trust concepts in action. 