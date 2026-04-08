.PHONY: build run test lint migrate-up migrate-down docker-build docker-up

build:
	go build -o bin/server ./cmd/server

run:
	go run ./cmd/server

test:
	go test ./... -v -race -cover

lint:
	golangci-lint run ./...

migrate-up:
	psql $(DATABASE_URL) -f migrations/001_initial_schema.sql
	psql $(DATABASE_URL) -f migrations/002_add_indexes.sql

migrate-down:
	psql $(DATABASE_URL) -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

docker-build:
	docker compose build

docker-up:
	docker compose up -d

docker-down:
	docker compose down
