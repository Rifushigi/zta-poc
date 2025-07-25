const winston = require('winston');

// Custom format for structured logging
const logFormat = winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
);

// Create logger instance
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: logFormat,
    defaultMeta: { service: 'backend-service' },
    transports: [
        // Write all logs with level 'error' and below to error.log
        new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
        // Write all logs with level 'info' and below to combined.log
        new winston.transports.File({ filename: 'logs/combined.log' }),
    ],
});

// Always log to the console, regardless of environment
logger.add(new winston.transports.Console({
    format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
    )
}));

// Create a stream object for Morgan
logger.stream = {
    write: (message) => {
        logger.info(message.trim());
    }
};

module.exports = logger; 