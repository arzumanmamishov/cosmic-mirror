# Cosmic Mirror / Lively — Next Steps (handoff)

_Last updated: 2026-07-06. Pick-up notes for continuing on another machine._

## How to build & run (reminders)
- **Go backend can't `go build` on a bare Windows host** — `internal/provider/swisseph` needs CGO + the Swiss Ephemeris C lib. Use Docker: `cd go_backend && docker compose up --build`.
- **Migrations** apply via `make migrate-up` (runs `001`…`010`). Migration `010_smtp_otp_auth.sql` is now included.
- **Flutter**: `flutter run` (debug → dev API). Release builds now auto-target `https://api.livelyapp.co`; override with `--dart-define=ENVIRONMENT=staging|dev` or `--dart-define=API_BASE_URL=...`.
- Auth is first-party **email-OTP + JWT** (not Firebase). With SMTP unset, the OTP code is printed to `docker compose logs -f api`.

## ✅ Done in the last session
- **Compatibility fixed end-to-end**: wired `SavedPeopleRepository`, implemented People list/add/delete with ownership checks, and made report generation load the saved person's real birth data (was passing a UUID string to the AI). Files: `go_backend/internal/{service/compatibility_service.go,handler/compatibility.go}`, `cmd/server/main.go`.
- **Real legal text** for `/legal/privacy` & `/legal/terms` → `go_backend/internal/handler/legal_text.go` (needs counsel review; fill `[Company Legal Entity]` / `[Jurisdiction]`).
- **iOS**: bundle id `com.cosmicmirror.cosmicMirror` → `com.arzuman.livelyapp` (matches Firebase); display name → "Lively".
- **Android**: real `key.properties`-based release signing (was debug keys). See `flutter_app/android/key.properties.example`. Keystore patterns added to `.gitignore`.
- **Flutter env**: release builds default to prod API instead of the dev LAN IP.
- **Website**: real `/privacy`, `/terms`, `/support` pages + wired footer links (`npm run build` passes).

## ▶️ NEXT CODING TASK — Push notifications (delivery)
The notifications worker (`go_backend/internal/worker/notifications.go`) currently only logs `"would send notification"`. Make it actually send:

1. **Migration** `011_device_tokens.sql`: `device_tokens(id, user_id, token, platform, created_at, updated_at)`, unique on `token`.
2. **Repo** `postgres/device_token_repo.go` + interface: `Upsert(userID, token, platform)`, `ListByUser(userID)`, `DeleteByToken(token)`.
3. **Endpoint** `POST /api/v1/users/me/device-tokens` (+ DELETE) — wire in `router.go`, handler on `UserHandler`.
4. **FCM sender**: add a Firebase Admin messaging client (`firebase.google.com/go/v4/messaging`) initialized from `FIREBASE_CREDENTIALS_PATH` in `main.go`; inject into `NotificationsWorker`. In `Run`, for each eligible user: generate text via existing `openai.BuildNotificationPrompt`, look up their device tokens, send, and record in `notification_logs`.
5. **Flutter client**: on login/app-start, request notification permission, get the FCM token (`firebase_messaging`), POST it to the new endpoint; handle token refresh. Foreground display via `flutter_local_notifications` (already a dep).
6. Needs `FIREBASE_CREDENTIALS_PATH` set (service-account JSON) to test — see owner tasks below.

## 🧰 Other deferred code work
- **Automated tests** — Go and Flutter are both ~0. Start with `compatibility_service` (people CRUD + report), auth/OTP, and a Flutter widget test for onboarding/paywall.
- **Crash reporting** — wire Firebase Crashlytics (TODOs in `flutter_app/lib/main.dart`).
- **CI/CD** — no `.github/workflows` yet: lint + test + Docker build for backend; `flutter analyze` + build for app; `next build` for website.

## 🔑 Owner setup (accounts / secrets / decisions — needed before store launch)
- [ ] **Rotate the OpenAI key** — a live key is in plaintext in `go_backend/.env` (uncommitted, but rotate).
- [ ] **Stripe / RevenueCat**: real keys (`--dart-define=STRIPE_PUBLISHABLE_KEY=...` + backend `.env`) and products in App Store Connect / Play Console.
- [ ] **Android keystore**: `keytool -genkey ...`, then copy `key.properties.example` → `key.properties` and fill in.
- [ ] **iOS signing**: set `DEVELOPMENT_TEAM` + provisioning profile in Xcode.
- [ ] **Firebase service-account JSON** on the backend (`FIREBASE_CREDENTIALS_PATH`) — required for push delivery.
- [ ] **Legal review** of the privacy/terms drafts; replace bracketed placeholders.
- [ ] **Deploy**: host backend + website, DNS + SSL for `api.livelyapp.co`, run migrations in prod.
