const express = require('express');
const axios = require('axios');
const jwt = require('jsonwebtoken');
const jwksRsa = require('jwks-rsa');
const { createProxyMiddleware } = require('http-proxy-middleware');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const winston = require('winston');
const promClient = require('prom-client');
const Joi = require('joi');
const cookieParser = require('cookie-parser');

const app = express();
const PORT = process.env.GATEWAY_PORT || 8000;
const BACKEND_URL = process.env.BACKEND_URL || 'http://backend-service:4000';
const OPA_URL = process.env.OPA_URL || 'http://opa:8181/v1/data/authz/allow';
const JWKS_URI = process.env.KEYCLOAK_JWKS_URI || 'http://keycloak:8080/realms/zero-trust/protocol/openid-connect/certs';
const KEYCLOAK_URL = process.env.KEYCLOAK_URL || 'http://keycloak:8080';
const KEYCLOAK_REALM = process.env.KEYCLOAK_REALM || 'zero-trust';
const KEYCLOAK_CLIENT_ID = process.env.KEYCLOAK_CLIENT_ID || 'myapp';
const KEYCLOAK_CLIENT_SECRET = process.env.KEYCLOAK_CLIENT_SECRET || 'EJO8EHORKiNmG6dQx3SFFoL7GwZChSOa';

// Winston logger setup
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    transports: [
        new winston.transports.Console(),
        new winston.transports.File({ filename: 'gateway-combined.log' })
    ]
});

// Morgan stream for winston
const morganStream = {
    write: (message) => logger.info(message.trim())
};

// Logging
app.use(morgan('combined', { stream: morganStream }));

// Cookie parser middleware
app.use(cookieParser());

// Body parser middleware for JSON
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// CORS middleware for frontend
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', 'http://localhost:8082');
    res.header('Access-Control-Allow-Credentials', 'true');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }
    next();
});

// JWT validation setup
const client = jwksRsa({ jwksUri: JWKS_URI });
function getKey(header, callback) {
    client.getSigningKey(header.kid, function (err, key) {
        if (err) return callback(err);
        callback(null, key.rsaPublicKey || key.publicKey);
    });
}

// Cookie-based JWT validation middleware
function cookieJwtMiddleware(req, res, next) {
    if (req.path === '/health' || req.path === '/metrics' || req.path === '/auth/login' || req.path === '/auth/logout') {
        return next();
    }

    const token = req.cookies.auth_token || req.headers['authorization']?.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'No authentication token provided' });
    }

    jwt.verify(token, getKey, { algorithms: ['RS256'] }, (err, decoded) => {
        if (err) {
            // Clear invalid cookie
            res.clearCookie('auth_token');
            return res.status(401).json({ error: 'Invalid or expired token', details: err.message });
        }
        req.user = decoded;
        req.token = token;
        next();
    });
}

// Authentication endpoints
app.post('/auth/login', async (req, res) => {
    try {
        const { username, password } = req.body;

        if (!username || !password) {
            return res.status(400).json({ error: 'Username and password are required' });
        }

        // Get token from Keycloak
        const tokenResponse = await axios.post(`${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/token`,
            new URLSearchParams({
                grant_type: 'password',
                client_id: KEYCLOAK_CLIENT_ID,
                client_secret: KEYCLOAK_CLIENT_SECRET,
                username: username,
                password: password
            }), {
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        });

        const { access_token, refresh_token } = tokenResponse.data;

        // Set HTTP-only cookie with the token
        res.cookie('auth_token', access_token, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'lax',
            maxAge: 15 * 60 * 1000 // 15 minutes
        });

        // Set refresh token in a separate cookie
        res.cookie('refresh_token', refresh_token, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'lax',
            maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
        });

        // Decode token to get user info
        const decoded = jwt.decode(access_token);

        res.json({
            success: true,
            user: {
                username: decoded.preferred_username,
                email: decoded.email,
                name: decoded.name,
                roles: decoded.realm_access?.roles || []
            }
        });

        logger.info('User logged in successfully', { username: decoded.preferred_username });

    } catch (error) {
        logger.error('Login failed', { error: error.message, username: req.body.username });

        if (error.response?.status === 401) {
            return res.status(401).json({ error: 'Invalid username or password' });
        }

        res.status(500).json({ error: 'Login failed', details: error.message });
    }
});

app.post('/auth/logout', (req, res) => {
    res.clearCookie('auth_token');
    res.clearCookie('refresh_token');
    res.json({ success: true, message: 'Logged out successfully' });
});

app.get('/auth/me', cookieJwtMiddleware, (req, res) => {
    res.json({
        user: {
            username: req.user.preferred_username,
            email: req.user.email,
            name: req.user.name,
            roles: req.user.realm_access?.roles || []
        }
    });
});

app.post('/auth/refresh', async (req, res) => {
    try {
        const refreshToken = req.cookies.refresh_token;

        if (!refreshToken) {
            return res.status(401).json({ error: 'No refresh token provided' });
        }

        // Refresh token with Keycloak
        const tokenResponse = await axios.post(`${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/token`,
            new URLSearchParams({
                grant_type: 'refresh_token',
                client_id: KEYCLOAK_CLIENT_ID,
                client_secret: KEYCLOAK_CLIENT_SECRET,
                refresh_token: refreshToken
            }), {
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        });

        const { access_token, refresh_token } = tokenResponse.data;

        // Update cookies
        res.cookie('auth_token', access_token, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'lax',
            maxAge: 15 * 60 * 1000 // 15 minutes
        });

        res.cookie('refresh_token', refresh_token, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'lax',
            maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
        });

        res.json({ success: true });

    } catch (error) {
        logger.error('Token refresh failed', { error: error.message });
        res.clearCookie('auth_token');
        res.clearCookie('refresh_token');
        res.status(401).json({ error: 'Token refresh failed' });
    }
});

// Legacy JWT validation middleware (for API clients that still use Authorization header)
function jwtMiddleware(req, res, next) {
    if (req.path === '/health' || req.path === '/metrics') return next();
    const authHeader = req.headers['authorization'];
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    const token = authHeader.split(' ')[1];
    jwt.verify(token, getKey, { algorithms: ['RS256'] }, (err, decoded) => {
        if (err) return res.status(401).json({ error: 'Invalid or expired token', details: err.message });
        req.user = decoded;
        req.token = token;
        next();
    });
}

// Prometheus metrics setup
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

const httpRequestDuration = new promClient.Histogram({
    name: 'gateway_http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status_code'],
    buckets: [0.05, 0.1, 0.2, 0.5, 1, 2, 5]
});
const httpRequestsTotal = new promClient.Counter({
    name: 'gateway_http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status_code']
});
const opaDecisions = new promClient.Counter({
    name: 'gateway_opa_decisions_total',
    help: 'Total number of OPA policy decisions',
    labelNames: ['result', 'route', 'user']
});
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestsTotal);
register.registerMetric(opaDecisions);

// Metrics endpoint
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
});

// Auditing middleware: log all requests and OPA decisions
app.use((req, res, next) => {
    const start = process.hrtime();
    res.on('finish', () => {
        const duration = process.hrtime(start);
        const durationSec = duration[0] + duration[1] / 1e9;
        const route = req.route?.path || req.path;
        httpRequestDuration.labels(req.method, route, res.statusCode).observe(durationSec);
        httpRequestsTotal.labels(req.method, route, res.statusCode).inc();
        logger.info('Request', {
            method: req.method,
            path: req.originalUrl,
            status: res.statusCode,
            user: req.user?.preferred_username || req.user?.sub,
            ip: req.ip,
            durationMs: Math.round(durationSec * 1000),
            requestId: req.headers['x-request-id']
        });
    });
    next();
});

// IP Whitelisting/Blacklisting Middleware
const ipWhitelist = process.env.GATEWAY_IP_WHITELIST ? process.env.GATEWAY_IP_WHITELIST.split(',').map(ip => ip.trim()) : null;
const ipBlacklist = process.env.GATEWAY_IP_BLACKLIST ? process.env.GATEWAY_IP_BLACKLIST.split(',').map(ip => ip.trim()) : [];

app.use((req, res, next) => {
    const clientIp = req.ip || req.connection.remoteAddress;
    if (ipWhitelist && !ipWhitelist.includes(clientIp)) {
        logger.warn('Blocked by IP whitelist', { ip: clientIp });
        return res.status(403).json({ error: 'Access denied: IP not whitelisted' });
    }
    if (ipBlacklist.includes(clientIp)) {
        logger.warn('Blocked by IP blacklist', { ip: clientIp });
        return res.status(403).json({ error: 'Access denied: IP blacklisted' });
    }
    next();
});

// OPA enforcement middleware
async function opaEnforce(req, res, next) {
    if (req.path === '/health' || req.path === '/metrics') return next();
    try {
        const input = {
            token: req.token,
            path: req.path,
            method: req.method,
            user: req.user,
        };
        const opaResp = await axios.post(OPA_URL, { input });
        logger.info('OPA decision', {
            path: req.path,
            method: req.method,
            user: req.user?.preferred_username || req.user?.sub,
            opaResult: opaResp.data.result,
            opaInput: input
        });
        opaDecisions.labels(
            String(opaResp.data.result),
            req.path,
            req.user?.preferred_username || req.user?.sub || 'unknown'
        ).inc();
        if (opaResp.data.result === true) return next();
        return res.status(403).json({ error: 'Forbidden by OPA policy' });
    } catch (err) {
        logger.error('OPA policy check failed', { error: err.message, path: req.path, user: req.user });
        return res.status(500).json({ error: 'OPA policy check failed', details: err.message });
    }
}

// Rate limiting middleware
const limiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
    max: parseInt(process.env.RATE_LIMIT_MAX) || 100, // limit each IP to 100 requests per windowMs
    message: { error: 'Too many requests, please try again later.' },
    standardHeaders: true,
    legacyHeaders: false,
});
app.use(limiter);

// Health endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: 'express-gateway', timestamp: new Date().toISOString() });
});

// Request validation middleware for /api/data POST
const dataSchema = Joi.object({
    name: Joi.string().min(1).required(),
    description: Joi.string().allow('').required()
});

app.use('/api/data', (req, res, next) => {
    if (req.method === 'POST') {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            try {
                const parsed = JSON.parse(body);
                const { error } = dataSchema.validate(parsed);
                if (error) {
                    logger.warn('Request validation failed', { error: error.details, path: req.path });
                    return res.status(400).json({ error: 'Validation failed', details: error.details });
                }
                req.body = parsed;
                next();
            } catch (e) {
                logger.warn('Invalid JSON in request body', { error: e.message, path: req.path });
                return res.status(400).json({ error: 'Invalid JSON', details: e.message });
            }
        });
    } else {
        next();
    }
});

// Add this before the proxy middleware
app.use((req, res, next) => {
    if (req.user) {
        req.headers['x-user'] = req.user.preferred_username || req.user.sub || 'unknown';
        req.headers['x-roles'] = Array.isArray(req.user.realm_access?.roles)
            ? req.user.realm_access.roles.join(',')
            : '';
    }
    next();
});

// Apply middlewares and proxy
app.use(cookieJwtMiddleware);
app.use(opaEnforce);
app.use('/api', createProxyMiddleware({
    target: BACKEND_URL,
    changeOrigin: true,
    onProxyReq: (proxyReq, req, res) => {
        if (req.user) {
            proxyReq.setHeader('x-user', req.user.preferred_username || req.user.sub || 'unknown');
            proxyReq.setHeader('x-roles', Array.isArray(req.user.realm_access?.roles)
                ? req.user.realm_access.roles.join(',')
                : '');
        }
    }
}));

// Custom error handling middleware
app.use((err, req, res, next) => {
    logger.error('Gateway error', {
        error: err.message,
        stack: err.stack,
        path: req.path,
        method: req.method,
        user: req.user?.preferred_username || req.user?.sub,
        requestId: req.headers['x-request-id']
    });
    res.status(err.status || 500).json({
        error: err.message || 'Internal gateway error',
        details: process.env.NODE_ENV !== 'production' ? err.stack : undefined,
        requestId: req.headers['x-request-id']
    });
});

app.listen(PORT, () => console.log(`Express Gateway listening on port ${PORT}`)); 