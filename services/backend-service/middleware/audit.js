const logger = require('../utils/logger');

const auditMiddleware = (operation) => {
    return (req, res, next) => {
        const originalSend = res.send;

        res.send = function (data) {
            // Log the operation after response is sent
            const auditLog = {
                operation,
                method: req.method,
                path: req.path,
                user: req.user?.username || 'unknown',
                userRoles: req.user?.roles || [],
                ip: req.ip,
                userAgent: req.get('User-Agent'),
                statusCode: res.statusCode,
                timestamp: new Date().toISOString(),
                requestId: req.headers['x-request-id'] || 'unknown'
            };

            // Add request body for create/update operations
            if (['create', 'update'].includes(operation) && req.body) {
                auditLog.requestBody = req.body;
            }

            // Add response data for successful operations
            if (res.statusCode >= 200 && res.statusCode < 300) {
                try {
                    const responseData = JSON.parse(data);
                    auditLog.responseData = responseData;
                } catch (e) {
                    // Response is not JSON, skip
                }
            }

            logger.info('Audit log', auditLog);

            // Call original send method
            originalSend.call(this, data);
        };

        next();
    };
};

module.exports = {
    auditMiddleware
}; 