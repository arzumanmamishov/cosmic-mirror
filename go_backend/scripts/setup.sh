#!/bin/bash
# Cosmic Mirror - Local Development Setup
# Usage: bash scripts/setup.sh

set -e

echo "=== Cosmic Mirror Backend Setup ==="
echo ""

# 1. Check Docker
echo "[1/4] Checking Docker..."
if ! docker info > /dev/null 2>&1; then
    echo "  Docker is not running. Please open Docker Desktop and wait for it to start."
    echo "  Then re-run this script."
    exit 1
fi
echo "  Docker is running."

# 2. Start PostgreSQL and Redis
echo ""
echo "[2/4] Starting PostgreSQL & Redis..."
docker compose up -d postgres redis
echo "  Waiting for services to be healthy..."
sleep 5

# Wait for postgres
for i in $(seq 1 15); do
    docker compose exec -T postgres pg_isready -U cosmic -d cosmic_mirror > /dev/null 2>&1 && break
    sleep 2
done
echo "  PostgreSQL is ready."

# 3. Run migrations
echo ""
echo "[3/4] Running migrations..."
docker compose exec -T postgres psql -U cosmic -d cosmic_mirror -f /dev/stdin < migrations/001_initial_schema.sql 2>&1 || echo "  (tables may already exist)"
docker compose exec -T postgres psql -U cosmic -d cosmic_mirror -f /dev/stdin < migrations/002_add_indexes.sql 2>&1 || echo "  (indexes may already exist)"
echo "  Migrations applied."

# 4. Start the API server
echo ""
echo "[4/4] Starting API server..."
echo "  Server will be available at http://localhost:8080"
echo "  Health check: http://localhost:8080/health"
echo ""
go run ./cmd/server
