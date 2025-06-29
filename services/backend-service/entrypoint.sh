#!/bin/sh
set -e

# Set environment variables
export NODE_ENV=production

# Ensure we're in the correct directory
cd /app

# Run migrations
npx sequelize-cli db:migrate --env production

# Check if Items table is empty, then seed if needed
ITEM_COUNT=$(npx sequelize-cli db:seed:all --env production --check | grep 'No seeders are pending' || true)
if [ -z "$ITEM_COUNT" ]; then
  echo "Seeding database with demo data..."
  npx sequelize-cli db:seed:all --env production
else
  echo "Database already seeded. Skipping seeder."
fi

# Start the app
npm start 