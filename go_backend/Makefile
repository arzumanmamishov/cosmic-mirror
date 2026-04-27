.PHONY: build run test lint migrate-up migrate-down docker-build docker-up docker-down docker-dev docker-logs dev db-up db-down

build:
	go build -o bin/server ./cmd/server

run:
	go run ./cmd/server

test:
	go test ./... -v -race -cover

lint:
	golangci-lint run ./...

# Start only PostgreSQL + Redis
db-up:
	docker compose up -d postgres redis

db-down:
	docker compose down

# Run migrations via Docker
migrate-up:
	docker compose exec -T postgres psql -U cosmic -d cosmic_mirror < migrations/001_initial_schema.sql
	docker compose exec -T postgres psql -U cosmic -d cosmic_mirror < migrations/002_add_indexes.sql

migrate-down:
	docker compose exec -T postgres psql -U cosmic -d cosmic_mirror -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

# Full dev setup: start DB, migrate, run server
dev: db-up
	@echo "Waiting for PostgreSQL..."
	@sleep 5
	@$(MAKE) migrate-up 2>/dev/null || echo "Tables may already exist"
	@echo "Starting server on http://localhost:8080"
	go run ./cmd/server

docker-build:
	docker compose build

docker-up:
	docker compose up -d

# Build and run the entire stack (api + postgres + redis) in Docker.
# This is the recommended path because the api requires CGO (Swiss Ephemeris).
docker-dev: docker-build
	docker compose up -d
	@echo "Waiting for services..."
	@sleep 8
	@$(MAKE) migrate-up 2>/dev/null || echo "Tables may already exist"
	@echo "API ready at http://localhost:8080/health"
	docker compose logs -f api

docker-logs:
	docker compose logs -f api
