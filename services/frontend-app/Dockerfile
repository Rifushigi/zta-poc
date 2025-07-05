# Dev stage
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install necessary packages
RUN apk add --no-cache bash

# Copy package files and install deps
COPY package*.json ./

RUN npm install ajv@^6.12.6 --save-exact
RUN npm install --legacy-peer-deps --omit=optional

# Expose the default React dev port
EXPOSE 3000

# Set environment for dev
ENV REACT_APP_API_URL=http://localhost:8000
ENV NODE_ENV=development

# Start the React dev server
CMD ["npm", "start"]
