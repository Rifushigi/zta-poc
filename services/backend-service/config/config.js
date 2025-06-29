require('dotenv').config();

module.exports = {
    development: {
        username: process.env.DB_USER || 'backend',
        password: process.env.DB_PASSWORD || 'backendpass',
        database: process.env.DB_NAME || 'zerotrust',
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 5432,
        dialect: 'postgres',
        logging: false
    },
    production: {
        username: process.env.DB_USER || 'backend',
        password: process.env.DB_PASSWORD || 'backendpass',
        database: process.env.DB_NAME || 'zerotrust',
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 5432,
        dialect: 'postgres',
        logging: false
    },
    test: {
        username: process.env.DB_USER || 'backend',
        password: process.env.DB_PASSWORD || 'backendpass',
        database: process.env.DB_NAME || 'zerotrust',
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 5432,
        dialect: 'postgres',
        logging: false
    }
}; 