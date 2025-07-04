require('dotenv').config();

const KEYCLOAK_JWKS_URI = process.env.KEYCLOAK_JWKS_URI || 'http://localhost:8080/realms/zero-trust/protocol/openid-connect/certs';
module.exports.KEYCLOAK_JWKS_URI = KEYCLOAK_JWKS_URI;

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