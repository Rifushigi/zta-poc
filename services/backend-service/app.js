require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const cors = require('cors');
const morgan = require('morgan');
const { v4: uuidv4 } = require('uuid');
const swaggerUi = require('swagger-ui-express');
const swaggerJsdoc = require('swagger-jsdoc');

// Import our utilities and middleware
const logger = require('./utils/logger');
const metrics = require('./utils/metrics');
const { validationMiddleware, queryValidationMiddleware } = require('./middleware/validation');
const { auditMiddleware } = require('./middleware/audit');
const { createItemSchema, updateItemSchema, paginationSchema } = require('./validations/itemValidation');

// Import Sequelize and models
const { Sequelize } = require('sequelize');
const Item = require('./models/item');

const app = express();
const port = process.env.PORT || 4000;

// Database connection
const sequelize = new Sequelize(
    process.env.DB_NAME || 'zerotrust',
    process.env.DB_USER || 'backend',
    process.env.DB_PASSWORD || 'backendpass',
    {
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 5432,
        dialect: 'postgres',
        logging: false,
        pool: {
            max: 5,
            min: 0,
            acquire: 30000,
            idle: 10000
        }
    }
);

// Security middleware
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: {
        error: 'Too many requests from this IP, please try again later.'
    },
    standardHeaders: true,
    legacyHeaders: false,
});
app.use(limiter);

// CORS configuration
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : ['http://localhost:4000'],
    credentials: true
}));

// Request ID middleware
app.use((req, res, next) => {
    req.headers['x-request-id'] = req.headers['x-request-id'] || uuidv4();
    res.setHeader('X-Request-ID', req.headers['x-request-id']);
    next();
});

// Logging middleware
app.use(morgan('combined', { stream: logger.stream }));

// Metrics middleware
app.use((req, res, next) => {
    const start = Date.now();

    res.on('finish', () => {
        const duration = Date.now() - start;
        const route = req.route ? req.route.path : req.path;

        metrics.httpRequestDurationMicroseconds
            .labels(req.method, route, res.statusCode)
            .observe(duration / 1000);

        metrics.httpRequestsTotal
            .labels(req.method, route, res.statusCode)
            .inc();
    });

    next();
});

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// User context middleware (extract from JWT passed by API Gateway)
app.use((req, res, next) => {
    req.user = {
        username: req.headers['x-user'] || 'unknown',
        roles: req.headers['x-roles'] ? req.headers['x-roles'].split(',') : [],
    };
    next();
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'backend-service',
        version: process.env.npm_package_version || '1.0.0'
    });
});

// Metrics endpoint for Prometheus
app.get('/metrics', async (req, res) => {
    try {
        res.set('Content-Type', metrics.register.contentType);
        res.end(await metrics.register.metrics());
    } catch (err) {
        logger.error('Error generating metrics', err);
        res.status(500).end();
    }
});

// Role-based access middleware
const requireRole = (roles) => (req, res, next) => {
    if (!req.user || !roles.some(role => req.user.roles.includes(role))) {
        return res.status(403).json({ error: 'Forbidden', details: `Requires role: ${roles.join(' or ')}` });
    }
    next();
};

// Swagger/OpenAPI setup
const swaggerOptions = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'Zero Trust API',
            version: '1.0.0',
            description: 'API documentation for the Zero Trust backend service.',
            contact: {
                name: 'Zero Trust Team',
                email: 'team@zerotrust.com'
            }
        },
        servers: [
            {
                url: 'http://localhost:4000',
                description: 'Development server'
            }
        ],
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT'
                }
            }
        },
        security: [{
            bearerAuth: []
        }]
    },
    apis: ['./routes/*.js', './app.js']
};
const swaggerSpec = swaggerJsdoc(swaggerOptions);
app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// CRUD endpoints for items with validation, auditing, and pagination
/**
 * @swagger
 * /api/data:
 *   get:
 *     summary: Get paginated items for the authenticated user
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *         description: Items per page
 *     responses:
 *       200:
 *         description: List of items
 *   post:
 *     summary: Create a new item
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *     responses:
 *       201:
 *         description: Created item
 */
app.get('/api/data', requireRole(['user', 'admin']), queryValidationMiddleware(paginationSchema), auditMiddleware('read'), async (req, res, next) => {
    try {
        const { page = 1, limit = 10 } = req.query;
        const offset = (page - 1) * limit;

        const { count, rows: items } = await Item.findAndCountAll({
            where: { owner: req.user.username },
            limit: parseInt(limit),
            offset: parseInt(offset),
            order: [['createdAt', 'DESC']]
        });

        metrics.databaseOperationsTotal
            .labels('select', 'Items', 'success')
            .inc();

        res.json({
            items,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total: count,
                pages: Math.ceil(count / limit)
            }
        });
    } catch (err) {
        metrics.databaseOperationsTotal
            .labels('select', 'Items', 'error')
            .inc();
        next(err);
    }
});

app.post('/api/data', requireRole(['user', 'admin']), validationMiddleware(createItemSchema), auditMiddleware('create'), async (req, res, next) => {
    try {
        const { name, description } = req.body;
        const item = await Item.create({
            name,
            description,
            owner: req.user.username
        });

        metrics.databaseOperationsTotal
            .labels('insert', 'Items', 'success')
            .inc();

        res.status(201).json({ item });
    } catch (err) {
        metrics.databaseOperationsTotal
            .labels('insert', 'Items', 'error')
            .inc();
        next(err);
    }
});

app.put('/api/data/:id', requireRole(['user', 'admin']), validationMiddleware(updateItemSchema), auditMiddleware('update'), async (req, res, next) => {
    try {
        const { id } = req.params;
        const { name, description } = req.body;

        const item = await Item.findOne({
            where: { id, owner: req.user.username }
        });

        if (!item) {
            return res.status(404).json({
                error: 'Item not found',
                details: 'The requested item does not exist or you do not have permission to access it'
            });
        }

        if (name !== undefined) item.name = name;
        if (description !== undefined) item.description = description;

        await item.save();

        metrics.databaseOperationsTotal
            .labels('update', 'Items', 'success')
            .inc();

        res.json({ item });
    } catch (err) {
        metrics.databaseOperationsTotal
            .labels('update', 'Items', 'error')
            .inc();
        next(err);
    }
});

app.delete('/api/data/:id', requireRole(['user', 'admin']), auditMiddleware('delete'), async (req, res, next) => {
    try {
        const { id } = req.params;
        const item = await Item.findOne({
            where: { id, owner: req.user.username }
        });

        if (!item) {
            return res.status(404).json({
                error: 'Item not found',
                details: 'The requested item does not exist or you do not have permission to access it'
            });
        }

        await item.destroy();

        metrics.databaseOperationsTotal
            .labels('delete', 'Items', 'success')
            .inc();

        res.json({
            message: 'Item deleted successfully',
            deletedItem: { id: item.id, name: item.name }
        });
    } catch (err) {
        metrics.databaseOperationsTotal
            .labels('delete', 'Items', 'error')
            .inc();
        next(err);
    }
});

/**
 * @swagger
 * /api/admin:
 *   get:
 *     summary: Get all items (admin only)
 *     parameters:
 */
app.get('/api/admin', requireRole(['admin']), queryValidationMiddleware(paginationSchema), auditMiddleware('admin_read'), async (req, res, next) => {
    try {
        if (!req.user.roles.includes('admin')) {
            return res.status(403).json({
                error: 'Forbidden',
                details: 'Admin role required to access this endpoint'
            });
        }

        const { page = 1, limit = 10 } = req.query;
        const offset = (page - 1) * limit;

        const { count, rows: items } = await Item.findAndCountAll({
            limit: parseInt(limit),
            offset: parseInt(offset),
            order: [['createdAt', 'DESC']]
        });

        metrics.databaseOperationsTotal
            .labels('select', 'Items', 'success')
            .inc();

        res.json({
            items,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total: count,
                pages: Math.ceil(count / limit)
            }
        });
    } catch (err) {
        metrics.databaseOperationsTotal
            .labels('select', 'Items', 'error')
            .inc();
        next(err);
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    logger.error('Unhandled error', {
        error: err.message,
        stack: err.stack,
        requestId: req.headers['x-request-id'],
        user: req.user?.username,
        path: req.path,
        method: req.method
    });

    // Don't leak error details in production
    const errorResponse = {
        error: 'Internal server error',
        requestId: req.headers['x-request-id']
    };

    if (process.env.NODE_ENV !== 'production') {
        errorResponse.details = err.message;
        errorResponse.stack = err.stack;
    }

    res.status(500).json(errorResponse);
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Not found',
        details: `The requested resource ${req.path} was not found`,
        requestId: req.headers['x-request-id']
    });
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('SIGTERM received, shutting down gracefully');
    await sequelize.close();
    process.exit(0);
});

process.on('SIGINT', async () => {
    logger.info('SIGINT received, shutting down gracefully');
    await sequelize.close();
    process.exit(0);
});

// Sync DB and start server
sequelize.sync({ alter: true }).then(() => {
    logger.info('Database synchronized successfully');
    app.listen(port, '0.0.0.0', () => {
        logger.info(`Backend service listening on port ${port}`);
    });
}).catch((err) => {
    logger.error('Failed to sync database', err);
    process.exit(1);
}); 