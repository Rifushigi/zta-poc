const promClient = require('prom-client');

// Create a Registry to register the metrics
const register = new promClient.Registry();

// Enable the collection of default metrics
promClient.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDurationMicroseconds = new promClient.Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status_code'],
    buckets: [0.1, 0.5, 1, 2, 5]
});

const httpRequestsTotal = new promClient.Counter({
    name: 'http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status_code']
});

const databaseOperationsTotal = new promClient.Counter({
    name: 'database_operations_total',
    help: 'Total number of database operations',
    labelNames: ['operation', 'table', 'status']
});

const activeConnections = new promClient.Gauge({
    name: 'active_connections',
    help: 'Number of active connections'
});

// Register metrics
register.registerMetric(httpRequestDurationMicroseconds);
register.registerMetric(httpRequestsTotal);
register.registerMetric(databaseOperationsTotal);
register.registerMetric(activeConnections);

module.exports = {
    register,
    httpRequestDurationMicroseconds,
    httpRequestsTotal,
    databaseOperationsTotal,
    activeConnections
}; 