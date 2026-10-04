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

Fill in every value. Generate secrets like this:

```sh
openssl rand -hex 32      # POSTGRES_PASSWORD, REDIS_PASSWORD
openssl rand -base64 48   # JWT_SECRET
```

The Postgres and Redis passwords must be hex. The compose file pastes them unescaped into `DATABASE_URL` and `REDIS_URL`, and the `/`, `+` and `=` in a base64 secret break URL parsing. The API checks both URLs at start-up and refuses to boot with a clear error if either one doesn't parse. `JWT_SECRET` never goes into a URL, so base64 is fine there.

| Setting | Why it matters |
|---|---|
| `POSTGRES_PASSWORD`, `REDIS_PASSWORD` | Required, hex only (`openssl rand -hex 32`). The stack refuses to start without them. |
| `JWT_SECRET` | 32+ characters. The server refuses to boot otherwise. Changing it signs everyone out. |
| `SMTP_*` | Required. Sign-in and password-reset codes are sent by email. |
| `API_DOMAIN`, `ACME_EMAIL` | Caddy uses these to get and renew the HTTPS certificate automatically. |
| `REVENUECAT_*` | Required to sell Premium in the apps (App Store / Google Play). See [5a](#5a-in-app-purchases-revenuecat). |
| `STRIPE_*` | Web checkout only (the apps never use Stripe). Use live keys. Register the webhook at `https://$API_DOMAIN/api/v1/stripe/webhook`. |
| `CORS_ORIGINS` | Only browser origins, such as the website. The apps don't need CORS. |
| `MODERATION_EMAIL`, `ADMIN_EMAILS` | Required for the app stores' user-generated-content rules. See [3c](#3c-community-moderation). |

`ENVIRONMENT` is forced to `prod` by the compose file. In prod the server refuses to boot on unsafe settings: a weak JWT secret, no SMTP, or Stripe without a webhook secret.

## 3. Deploy

```sh
make prod-up        # build and start caddy + api + postgres + redis
make prod-logs      # follow api + caddy logs
curl https://$API_DOMAIN/ready    # {"status":"ready"} once Postgres and Redis answer
```

* **Migrations** are embedded in the binary and run automatically at start-up. They are tracked in `schema_migrations` and guarded by an advisory lock. A database that was migrated by hand (one with tables but no `schema_migrations`) is baselined on first start. Each pre-runner migration (001–011) is checked for its schema change. The ones already present are recorded as applied. Everything from the first missing one onwards runs normally.
* **Updates:** `git pull && make prod-up`. The API restarts, and pending migrations run first.
* **Health endpoints:** `/health` is liveness and is used by the container healthcheck. `/ready` checks Postgres and Redis and is used by Caddy.
* **Image versions** for Caddy, Postgres and Redis are pinned in `docker-compose.prod.yml`. Bump them on purpose and read the release notes first. Don't change the Postgres major version (15) without a dump and restore. Redis must be 7.0 or newer, because the rate limiters use `EXPIRE … NX`.
* **Shutdown:** the API gets 75 seconds (`stop_grace_period`) to finish in-flight requests before Docker kills it.

## 3a. Place search (geocoding)

The birthplace search (`/api/v1/places/search`) proxies the public OpenStreetMap Nominatim server. Its [usage policy](https://operations.osmfoundation.org/policies/nominatim/) allows at most 1 request per second for the whole app, requires an identifying User-Agent, and requires caching. The API handles this in four ways:

* It sends `User-Agent: Lively/1.0 (+https://livelyapp.co; hello@livelyapp.co)`.
* It caches results for 30 days, or 1 day for empty results.
* It throttles upstream calls to 1 per second. If more than 3 seconds of requests are already queued, the user gets a 503 "try again" response instead.
* It limits each IP to 30 searches per minute and requires queries of at least 3 characters.

Caveats:

* The throttle is per API instance. If you run more than one replica, the combined rate is N requests per second, which breaks the policy.
* The cache is in process unless the handler is given Redis (`NewPlacesHandler().WithRedis(rdb)` in `cmd/server/main.go`).
* The public Nominatim server is a stop-gap. Before traffic grows, switch to a paid geocoder (for example LocationIQ, OpenCage, Mapbox or Google) or a self-hosted Nominatim. Nominatim can block the app without warning. If that happens, the endpoint returns 503 and onboarding can't resolve birthplaces.

## 3b. Sign-in abuse limits

* **Per IP:** 30 auth requests per minute. The limit is loose on purpose, because carrier-grade NAT puts many phones behind one IP.
* **Per email, for codes:** 3 code requests per 10 minutes and 10 per day.
* **Per email, for guesses:** 5 guesses per code. After 10 wrong codes in 24 hours, the email can't verify or request codes until the oldest failures are more than 24 hours old (HTTP 429 `account_locked`).
* **Per email, for passwords:** 10 wrong passwords lock password login for 15 minutes.

The OTP counters live in Postgres (`email_otps`). To unlock a real user early (support request), run:

```sh
docker compose -f docker-compose.prod.yml --env-file .env.production exec postgres \
  psql -U cosmic -d cosmic_mirror -c "DELETE FROM email_otps WHERE email = 'user@example.com';"
```

## 3c. Community moderation

Apple (guideline 1.2) and Google Play (UGC policy) require a way to report content, a way to block users, and a developer who acts on reports within 24 hours. The app and the API provide all three. You need to watch the moderation inbox.

**Settings**

| Setting | Default | What it does |
|---|---|---|
| `MODERATION_EMAIL` | empty | Inbox that gets one email per new report. If it's empty, reports are only stored, and the server logs a warning at start-up. |
| `ADMIN_EMAILS` | empty | Comma-separated account emails that may call `/api/v1/admin/*`. Everyone else gets 403. If it's empty, nobody can. |
| `MODERATION_AUTOHIDE_THRESHOLD` | `3` | A post or comment that gets this many open reports from different users is hidden right away. It stays hidden until you review it. Set it to `0` to turn auto-hide off. |

Report emails use the same SMTP settings as sign-in codes.

**What users can do**

* **Report** a post, comment, space or user: `POST /api/v1/reports`. Each user can report the same item only once; reporting it again returns the existing report. Users can't report their own content. Each user can send 10 reports per minute.
* **Block** a user: `POST` or `DELETE /api/v1/users/{id}/block`. Blocked users are listed at `GET /api/v1/users/me/blocks`. A block hides content in both directions: posts, comments, member lists, notifications, popular hashtags, and space discovery. It also stops comments, likes and notifications between the two users.
* Space owners and mods can delete comments in their space.

**Hidden and banned content.** Hidden content is visible only to its author. Every authenticated request from a banned account gets 403 `account_banned`, and its content is hidden from everyone.

**Handling a report.** Sign in to the app with an `ADMIN_EMAILS` account and copy the access token. Then list and resolve reports:

```sh
TOKEN=...   # the admin's access token
curl -H "Authorization: Bearer $TOKEN" "https://$API_DOMAIN/api/v1/admin/reports?status=open"
curl -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"action":"hide","note":"harassment"}' \
  "https://$API_DOMAIN/api/v1/admin/reports/<report-id>/resolve"
```

Each action closes every open report on the same item:

| Action | Effect | Report status |
|---|---|---|
| `dismiss` | No violation. Un-hides an auto-hidden post or comment. | `dismissed` |
| `hide` | Hides the post or comment. Not available for spaces or users. | `actioned` |
| `delete` | Deletes the post, comment or space. | `actioned` |
| `ban_user` | Bans the owner (author, space creator or reported user) and signs them out everywhere. | `actioned` |

**SQL fallbacks** (if the API is down). Use the same `psql` prefix as in [3b](#3b-sign-in-abuse-limits): `docker compose -f docker-compose.prod.yml --env-file .env.production exec postgres psql -U cosmic -d cosmic_mirror -c "..."`.

```sql
-- Open reports, oldest first
SELECT id, target_type, target_id, reason, details, created_at
FROM content_reports WHERE status = 'open' ORDER BY created_at;

-- Hide a post or comment (set hidden_at = NULL to un-hide)
UPDATE posts    SET hidden_at = NOW() WHERE id = '<post-id>';
UPDATE comments SET hidden_at = NOW() WHERE id = '<comment-id>';

-- Ban a user and sign them out everywhere (set banned_at = NULL to unban)
UPDATE users SET banned_at = NOW() WHERE id = '<user-id>';
UPDATE refresh_tokens SET revoked_at = NOW() WHERE user_id = '<user-id>' AND revoked_at IS NULL;

-- Close the reports for an item
UPDATE content_reports SET status = 'actioned', reviewed_at = NOW(), reviewed_note = '...'
WHERE target_type = 'post' AND target_id = '<post-id>' AND status = 'open';
```

The tables come from migration `015_moderation.sql`: `content_reports`, `user_blocks`, `posts.hidden_at`, `comments.hidden_at` and `users.banned_at`.

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
REVENUECAT_API_KEY_IOS=appl_... REVENUECAT_API_KEY_ANDROID=goog_... ./scripts/build_release.sh
```

* The RevenueCat keys are the public SDK keys from RevenueCat → Project settings → API keys. iOS keys start with `appl_` and Android keys with `goog_`. The script refuses a missing key or a key for the wrong store, because the app would otherwise ship with purchases turned off. `REVENUECAT_API_KEY` still works as a fallback if it matches the platform.
* Release builds default to `ENVIRONMENT=prod` and `https://api.livelyapp.co`. Cleartext HTTP is only allowed in Android debug builds.
* The script builds with `--obfuscate --split-debug-info`. Keep `build/debug-info/` privately, because you need it to symbolicate crash reports.
* **Android:** create the upload keystore and `android/key.properties` (see `key.properties.example`). Release builds fail without them.
* **iOS:** set the signing team in Xcode and archive, or use `flutter build ipa`.

## 5a. In-app purchases (RevenueCat)

The apps sell Premium only through App Store and Google Play in-app purchases, using RevenueCat (App Store guideline 3.1.1 and Google Play's payments policy). Stripe is only for web checkout. Premium is active when either an App Store / Google Play subscription or a Stripe subscription is active.

How it works:

* After sign-in the app calls `Purchases.logIn(<user id>)`, so the RevenueCat app user ID is the user's UUID. Sign-out and account deletion call `Purchases.logOut()`.
* The paywall shows the `default` offering's monthly and annual packages with the store's localized prices. It shows the free trial only if the annual product has a free-trial introductory offer and the user is still eligible for it.
* RevenueCat calls `POST https://$API_DOMAIN/api/v1/subscription/webhook`. For each event, the API fetches the user's current state from the RevenueCat REST API (`GET /v1/subscribers/{app_user_id}`) and stores it in the `rc_*` columns of `subscriptions` (migration 014). If `REVENUECAT_SECRET_API_KEY` isn't set, it uses the event payload instead. Retried and out-of-order events are harmless. Anonymous IDs (`$RCAnonymousID…`) are ignored until RevenueCat links the purchase to a user.
* `GET /api/v1/subscription/status` returns `is_premium`, `source` (`revenuecat` or `stripe`), `store`, `expires_at`, `is_trial` and `will_renew`.
* The server can't cancel App Store or Google Play subscriptions. The delete-account dialog tells users to cancel in their store settings.

**1. App Store Connect**

1. Accept the Paid Applications Agreement and fill in tax and banking details. Without them, products don't load.
2. Create a subscription group, such as "Lively Premium", with two auto-renewable subscriptions: `lively_premium_monthly` (1 month) and `lively_premium_yearly` (1 year). Set prices, and add a display name and description for each language.
3. On `lively_premium_yearly`, add an introductory offer: **Free trial, 3 days**, for all territories. Apple applies its own eligibility rules: a user gets one introductory offer per subscription group.
4. Create an In-App Purchase key (Users and Access → Integrations) and upload it to RevenueCat. Also set the App Store Server Notifications URL to the one RevenueCat gives you.
5. Submit both products with the app version the first time you submit it. Add a screenshot of the paywall for review.
6. In the app's metadata, set the Privacy Policy URL to `https://livelyapp.co/privacy`. For the Terms of Use, either use Apple's standard EULA or link `https://livelyapp.co/terms` in the description or the EULA field. The paywall links both pages.

**2. Google Play Console**

1. Create two subscriptions, `lively_premium_monthly` and `lively_premium_yearly`, each with an auto-renewing base plan (`monthly`, billed every month, and `yearly`, billed every year). RevenueCat shows them as `lively_premium_yearly:yearly` and so on. The server works out the plan from the product ID, so keep `month` or `year` in it.
2. On the yearly base plan, add an offer with one phase: **Free trial, 3 days**. Set eligibility to "New customer acquisition" (users who never had this subscription).
3. Give RevenueCat's service account access with the financial permissions, upload the JSON key to RevenueCat, and turn on Real-time developer notifications (the Pub/Sub topic RevenueCat gives you).

**3. RevenueCat dashboard**

1. Add the iOS app (bundle ID `com.arzuman.livelyapp`) and the Android app (package `com.arzuman.livelyapp`). Import the four products.
2. Create the entitlement **`premium`** and attach all four products to it. The app checks this ID (`AppConstants.premiumEntitlement`) and so does the server (`REVENUECAT_ENTITLEMENT_ID`, default `premium`).
3. Create the offering **`default`** and mark it as current. Add the package **Monthly** (`$rc_monthly`) with both monthly products and **Annual** (`$rc_annual`) with both yearly products.
4. Integrations → Webhooks: set the URL to `https://$API_DOMAIN/api/v1/subscription/webhook`. Set the Authorization header value to the same random string as `REVENUECAT_WEBHOOK_SECRET` (`openssl rand -hex 32`). The server accepts it with or without `Bearer `. Send a test event. It should return 200.
5. Project settings → API keys: copy the secret key (`sk_…`) into `REVENUECAT_SECRET_API_KEY`. Copy the public `appl_…` and `goog_…` keys into the build (see section 5).

Sandbox and TestFlight purchases are accepted by the production server on purpose: App Review buys with sandbox accounts against the production API.

**Web (Stripe).** The yearly price gets a 3-day free trial for users who have never had a subscription or trial from any source, checked against our database and the Stripe customer's history. In a trial, `POST /api/v1/stripe/payment-sheet` returns `intent_type: "setup"` and a SetupIntent client secret. The card is saved and charged when the trial ends. A trial grants Premium only once a card is on file. If the trial ends without a card, the subscription is cancelled. Before launch, test this in Stripe test mode: confirm that the `customer.subscription.updated` webhook arrives after the SetupIntent succeeds and that it unlocks Premium.

## 6. Go-live checklist

- [ ] DNS points to the server, and `https://$API_DOMAIN/ready` returns `ready`.
- [ ] `.env.production` is filled in, `chmod 600`, and not committed.
- [ ] Sign-in email arrives (SPF, DKIM and DMARC set for the sending domain).
- [ ] Stripe (web only) is in live mode, and a test webhook delivers successfully in the Stripe dashboard.
- [ ] In-app purchases are set up as described in [5a](#5a-in-app-purchases-revenuecat): products `lively_premium_monthly` and `lively_premium_yearly` (yearly with a 3-day free trial) in App Store Connect and Play Console, entitlement `premium`, and offering `default` as current.
- [ ] `REVENUECAT_WEBHOOK_SECRET` and `REVENUECAT_SECRET_API_KEY` are set, and a RevenueCat test webhook returns 200.
- [ ] On a real device with a sandbox or test account: the paywall shows store prices and the trial, a purchase unlocks Premium, `GET /subscription/status` reports `"source":"revenuecat"` within seconds, Restore Purchases works after a reinstall, and a premium user sees "Manage subscription" instead of the plans.
- [ ] Release builds were made with `REVENUECAT_API_KEY_IOS` (`appl_…`) and `REVENUECAT_API_KEY_ANDROID` (`goog_…`).
- [ ] Nightly backup cron is installed, off-site copy is set up, and a restore has been tested.
- [ ] Release builds point to production. Check that login works on a real device.
- [ ] Store listings have a privacy policy URL (`/api/v1/legal/privacy`) and a terms URL.
- [ ] Monitoring: an uptime check on `/ready`, and a crash reporter on the apps (recommended).
- [ ] `MODERATION_EMAIL` and `ADMIN_EMAILS` are set. File a test report from the app, check that the email arrives, then resolve it with the admin API. Someone checks the inbox at least once a day.
