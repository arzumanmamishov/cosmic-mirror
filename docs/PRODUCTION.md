# Production runbook

How to run the Lively backend in production and ship the mobile apps.

## 1. Server

Any Linux VPS with Docker and Docker Compose works. Minimum: 2 vCPU, 4 GB RAM, 40 GB disk.

1. Point DNS: an `A` record (plus `AAAA` for IPv6) for your API domain, such as `api.livelyapp.co`, to the server.
2. Open the firewall for ports 22, 80 and 443 only. Postgres and Redis are never published.
3. Clone the repository to `/srv/cosmic-mirror`.

## 2. Configure

```sh
cd /srv/cosmic-mirror/go_backend
cp .env.production.example .env.production
chmod 600 .env.production
```

Fill in every value. Generate secrets with `openssl rand -base64 48`.

| Setting | Why it matters |
|---|---|
| `POSTGRES_PASSWORD`, `REDIS_PASSWORD` | Required. The stack refuses to start without them. |
| `JWT_SECRET` | 32+ characters. The server refuses to boot otherwise. Changing it signs everyone out. |
| `SMTP_*` | Required. Sign-in and password-reset codes are sent by email. |
| `API_DOMAIN`, `ACME_EMAIL` | Caddy uses these to get and renew the HTTPS certificate automatically. |
| `STRIPE_*` | Use live keys. Register the webhook at `https://$API_DOMAIN/api/v1/stripe/webhook`. |
| `CORS_ORIGINS` | Only browser origins, such as the website. The apps don't need CORS. |

`ENVIRONMENT` is forced to `prod` by the compose file. In prod the server refuses to boot on unsafe settings: a weak JWT secret, no SMTP, or Stripe without a webhook secret.

## 3. Deploy

```sh
make prod-up        # build and start caddy + api + postgres + redis
make prod-logs      # follow api + caddy logs
curl https://$API_DOMAIN/ready    # {"status":"ready"} once Postgres and Redis answer
```

* **Migrations** are embedded in the binary and run automatically at start-up. They are tracked in `schema_migrations` and guarded by an advisory lock. A database that was migrated by hand is baselined on first start.
* **Updates:** `git pull && make prod-up`. The API restarts, and pending migrations run first.
* **Health endpoints:** `/health` is liveness and is used by the container healthcheck. `/ready` checks Postgres and Redis and is used by Caddy.

## 4. Backups

```sh
crontab -e
15 3 * * *  cd /srv/cosmic-mirror/go_backend && deploy/backup.sh >> backups/backup.log 2>&1
```

* This keeps 14 days of `pg_dump` files in `go_backend/backups/`.
* Copy them off the server as well (S3, Backblaze or another host).
* Test a restore at least once. The command is in `deploy/backup.sh`.
* Uploaded avatars live in the `uploads_data` volume, so back that up too.

## 5. Mobile apps

```sh
cd flutter_app
./scripts/build_release.sh
```

* Release builds default to `ENVIRONMENT=prod` and `https://api.livelyapp.co`. Cleartext HTTP is only allowed in Android debug builds.
* The script builds with `--obfuscate --split-debug-info`. Keep `build/debug-info/` privately, because you need it to symbolicate crash reports.
* **Android:** create the upload keystore and `android/key.properties` (see `key.properties.example`). Release builds fail without them.
* **iOS:** set the signing team in Xcode and archive, or use `flutter build ipa`.

## 6. Go-live checklist

- [ ] DNS points to the server, and `https://$API_DOMAIN/ready` returns `ready`.
- [ ] `.env.production` is filled in, `chmod 600`, and not committed.
- [ ] Sign-in email arrives (SPF, DKIM and DMARC set for the sending domain).
- [ ] Stripe is in live mode, and a test webhook delivers successfully in the Stripe dashboard.
- [ ] Nightly backup cron is installed, off-site copy is set up, and a restore has been tested.
- [ ] Release builds point to production. Check that login works on a real device.
- [ ] Store listings have a privacy policy URL (`/api/v1/legal/privacy`) and a terms URL.
- [ ] Monitoring: an uptime check on `/ready`, and a crash reporter on the apps (recommended).
