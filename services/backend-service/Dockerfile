FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Force install compatible ajv version
RUN npm install ajv@^6.12.6

# Install all dependencies (including dev dependencies for sequelize-cli)
RUN npm install --legacy-peer-deps

# Copy application code
COPY . .

# Create logs directory
RUN mkdir -p logs

# Expose port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Use entrypoint script for idempotent seeding and startup
ENTRYPOINT ["/bin/sh", "./entrypoint.sh"] 