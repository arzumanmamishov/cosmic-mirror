#!/usr/bin/env bash
# Nightly Postgres backup for the production stack.
#   crontab:  15 3 * * *  cd /srv/cosmic-mirror/go_backend && deploy/backup.sh >> backups/backup.log 2>&1
# Keeps RETENTION_DAYS of compressed custom-format dumps in ./backups.
# Copy them off the server too (S3, Backblaze, another host) — a backup
# on the same disk doesn't survive losing the disk.
#
# Restore:  docker compose -f docker-compose.prod.yml exec -T postgres \
#             pg_restore -U cosmic -d cosmic_mirror --clean --if-exists < backups/<file>.dump
set -euo pipefail
cd "$(dirname "$0")/.."

RETENTION_DAYS="${RETENTION_DAYS:-14}"
mkdir -p backups
out="backups/cosmic_mirror_$(date -u +%Y%m%dT%H%M%SZ).dump"

docker compose -f docker-compose.prod.yml --env-file .env.production exec -T postgres \
  pg_dump -U cosmic -d cosmic_mirror -Fc > "$out.partial"
mv "$out.partial" "$out"
echo "$(date -u +%FT%TZ) backup ok: $out ($(du -h "$out" | cut -f1))"

find backups -name 'cosmic_mirror_*.dump' -mtime +"$RETENTION_DAYS" -delete
