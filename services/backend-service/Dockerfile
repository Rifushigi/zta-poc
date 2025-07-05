FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev dependencies for sequelize-cli)
RUN npm install --legacy-peer-deps

# Copy application code
COPY . .

# Create logs directory
RUN mkdir -p logs

# Expose port
EXPOSE 4000

# Use entrypoint script for idempotent seeding and startup
ENTRYPOINT ["/bin/sh", "./entrypoint.sh"] 