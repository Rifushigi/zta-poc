#!/bin/sh
set -e

# Run migrations
npm run db:migrate

# Check if Items table is empty, then seed if needed
ITEM_COUNT=$(npx sequelize-cli db:seed:all --check | grep 'No seeders are pending' || true)
if [ -z "$ITEM_COUNT" ]; then
  echo "Seeding database with demo data..."
  npm run db:seed
else
  echo "Database already seeded. Skipping seeder."
fi

# Start the app
npm start 