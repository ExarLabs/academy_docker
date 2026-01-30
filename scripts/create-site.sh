#!/bin/bash
# Script to create a new Frappe site with Academy apps

set -e

# Check if site name is provided
if [ -z "$1" ]; then
    echo "❌ Usage: $0 <site-name>"
    echo "Example: $0 academy.example.com"
    exit 1
fi

SITE_NAME=$1

echo "🌐 Creating new site: $SITE_NAME"

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -E '^[A-Z_][A-Z0-9_]*=' | sed 's/#.*$//' | xargs)
else
    echo "❌ .env file not found. Please create it from .env.example"
    exit 1
fi

# Create the site
echo "📦 Creating Frappe site..."
docker compose exec -T backend bench new-site \
    --no-mariadb-socket \
    --admin-password="$ADMIN_PASSWORD" \
    --db-root-password="$MARIADB_ROOT_PASSWORD" \
    "$SITE_NAME"

# Set Redis communication with Langchain
echo "Enabling redis communication between LMS and Langchain"
docker compose exec -T backend bench --site "$SITE_NAME" set-config langchain_use_redis true

# Install LMS
echo "📦 Installing Academy LMS..."
docker compose exec -T backend bench --site "$SITE_NAME" install-app lms

# Download Payments App (if needed)
if docker compose exec -T backend test -d apps/payments; then
    echo "✅ Payments App already downloaded"
else
    echo "📦 Downloading Payments App..."
    docker compose exec -T backend bench get-app payments
fi

# Ensure Payments is installed into the Python environment (editable install)
echo "🐍 Installing Payments Python package into venv..."
docker compose exec -T backend bash -lc 'cd /home/frappe/frappe-bench && pip install -e apps/payments && python -c "import payments;"'

# Install Payments App
echo "📦 Installing Payments App..."
docker compose exec -T backend bench --site "$SITE_NAME" install-app payments

# Set as default site (optional)
SET_DEFAULT_SITE_FLAG="${2:-n}"
echo
if [[ $SET_DEFAULT_SITE_FLAG =~ ^[Yy]$ ]]; then
    docker compose exec -T backend bench use "$SITE_NAME"
    echo "✅ Set as default site"
fi

# Clear cache
echo "🧹 Clearing cache..."
docker compose exec -T backend bench --site "$SITE_NAME" clear-cache

# Run migrations
echo "🔄 Running migrations..."
docker compose exec -T backend bench --site "$SITE_NAME" migrate

# Restarting backend
echo "🔄 Restarting backend..."
docker compose restart backend

# Download and Install payments in queue workers to
echo "📦 Downloading and installing Payments app for queue-short container..."
docker compose exec queue-short bash -lc 'cd /home/frappe/frappe-bench/apps && git clone https://github.com/frappe/payments.git && pip install -e payments'

echo "📦 Downloading and installing Payments app for queue-long container..."
docker compose exec queue-long bash -lc 'cd /home/frappe/frappe-bench/apps && git clone https://github.com/frappe/payments.git && pip install -e payments'

echo "🔄 Recreating queue-short and queue-long containers..."
docker compose up -d --force-recreate --pull never queue-short queue-long

echo "✅ Site created successfully!"
echo ""
echo "📋 Site details:"
echo "URL: http://$SITE_NAME"
echo "Username: Administrator"
echo "Password: $ADMIN_PASSWORD"
echo ""
echo "🔐 Remember to:"
echo "1. Update your DNS to point to the server IP"
echo "2. Configure SSL certificate for production"
echo "3. Update nginx configuration if needed"
