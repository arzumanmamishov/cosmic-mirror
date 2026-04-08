# Cosmic Mirror — Complete Production Blueprint

## 1. Product Spec

### Summary
Cosmic Mirror is a premium mobile astrology and self-guidance app that blends birth-chart personalization, AI-powered reflection, compatibility analysis, timeline forecasts, daily rituals, and journaling into a habit-forming daily experience.

### Target Audience
- Spiritually curious adults aged 22–45, primarily women
- Interest in self-improvement, mindfulness, and emotional intelligence
- Comfortable with subscription apps; likely users of meditation, wellness, or personality apps

### Feature List
- Full birth-chart onboarding (date, time, unknown-time fallback, birthplace geocoding)
- Sun / Moon / Rising reveal with emotional first impressions
- Personalized daily reading: energy level, emotional, love, career, health, caution, action, affirmation, lucky color, lucky number
- AI astrologer chat grounded in natal chart context
- Compatibility reports: emotional fit, communication, chemistry, conflict, advice
- Life timeline: 30-day, 3-month, 12-month forecasts
- Yearly forecast with quarterly breakdowns
- Daily rituals: morning intention, affirmation, evening reflection
- Journal with mood tracking and prompts
- Push notifications (timezone-aware, personalized)
- Subscription paywall with trial

### Free vs Premium

| Feature | Free | Premium |
|---------|------|---------|
| Daily reading | Summary only | Full (all categories) |
| AI chat | 3 messages/day | Unlimited |
| Compatibility | Score preview | Full report |
| Timeline | 7-day preview | 30d / 3m / 12m |
| Yearly forecast | — | Full |
| Rituals & Journal | — | Full |
| Chart details | Sun/Moon/Rising | All planets, houses, aspects |

### Pricing
- Monthly: €6.99/month
- Yearly: €39.99/year (saves 52%)
- 3-day free trial on yearly plan
- Restore purchases support required by App Store

### Retention Strategy
- Daily push notifications with personalized cosmic insights
- Streak tracking for ritual completion
- New daily reading content every day
- Journal prompts that change based on transits
- Weekly email digest with highlights

### Viral Features
- Shareable compatibility score cards (image + link)
- Shareable daily affirmation cards
- "Check your compatibility" invite flow
- Social proof on paywall ("Join 50,000+ cosmic explorers")

---

## 2. UI/UX Architecture

### Design Direction
- Dark cosmic aesthetic: deep navy background, purple/pink gradients, gold accents
- Glassmorphism cards for featured content
- Gradient borders for premium content
- Playfair Display for headings (elegant serif), Inter for body (clean sans-serif)
- Motion: subtle fade-ins, slide-up cards, scale animations for reveals

### Screen Flow

```
Splash → [Auth Check]
  ├─ Not authenticated → Auth Screen
  ├─ No birth profile → Onboarding Flow
  ├─ Not seen paywall → Paywall
  └─ Complete → Home Dashboard

Home Dashboard (bottom nav: Home, Chart, Chat, Profile)
  ├─ Daily Reading Detail
  ├─ AI Chat → Thread → Messages
  ├─ Compatibility → Add Person → Report
  ├─ Timeline (30d / 3m / 12m)
  ├─ Yearly Forecast
  ├─ Rituals
  ├─ Journal → Entry
  ├─ Chart (planets, houses, aspects, elements)
  └─ Settings → Profile, Notifications, Legal, Delete Account
```

### Key Screen Specs

**Splash**: Check Firebase auth → check onboarding status → route accordingly. Show logo + loading animation.

**Auth**: Apple Sign-In (iOS), Google Sign-In, Email/Password. Cosmic gradient background. Error messages inline. Terms/Privacy links at bottom.

**Onboarding** (6 steps with progress bar):
1. Birth date (Cupertino date picker)
2. Birth time (time picker + "I don't know" toggle)
3. Birthplace (autocomplete search → geocode to lat/lng/timezone)
4. First name
5. Focus areas (optional multi-select grid)
6. Chart reveal (animated Sun/Moon/Rising cards)

**Paywall**: Premium badge, 6 benefit items with icons, monthly/yearly toggle, trial badge on yearly, subscribe CTA, restore link, close button, compliance text.

**Home Dashboard**: Greeting with name, today's energy card (glassmorphism), quick action buttons (Chat, Compatibility, Timeline, Chart), daily affirmation card (gradient border), streak widget.

**Daily Reading**: Energy bar (1-10), sections for Emotional (free), Love (premium), Career (premium), Health (premium), Caution (free), Action (free), Affirmation card, Lucky color/number. Share button.

**AI Chat**: Thread list with last message preview. New conversation with suggested prompts. Message bubbles (user right, assistant left with avatar). Typing indicator. Premium gate after free limit.

**Compatibility**: Saved people list with score badges. Add person flow (name + birth data). Report with circular score cards (emotional, communication, chemistry), conflict patterns, advice. Share button.

**Chart**: Tabbed view (Planets, Houses, Aspects, Elements). Planet list with sign, house, degree, retrograde indicator. Element breakdown with progress bars.

---

## 3. Design System

### Color Palette
| Token | Hex | Usage |
|-------|-----|-------|
| background | #0A0E27 | App background |
| surface | #141833 | Card backgrounds |
| surfaceLight | #1E2347 | Input fields, elevated surfaces |
| primary | #6C3CE1 | Primary actions, links |
| primaryLight | #8B5CF6 | Hover states, highlights |
| accent | #E14B8A | Secondary actions, love/compatibility |
| gold | #F4C542 | Highlights, premium, affirmations |
| textPrimary | #F0EFF4 | Main text |
| textSecondary | #8E8BA3 | Supporting text |
| textTertiary | #5C5A6E | Disabled text |
| success | #34D399 | Positive indicators |
| warning | #FBBF24 | Caution indicators |
| error | #F87171 | Error states |

### Typography
- Display: Playfair Display (28-32sp, weight 600-700)
- Headlines: Inter (18-22sp, weight 600-700)
- Body: Inter (14-16sp, weight 400, line-height 1.5)
- Caption: Inter (12-13sp, weight 400)
- Overline: Inter (11sp, weight 600, letter-spacing 1.5px)
- Affirmation: Playfair Display Italic (20sp, gold color)

### Spacing
Base unit: 4px. Common values: 8, 12, 16, 20, 24, 32, 48px.

### Components
- **Cards**: 16px border radius, surface background, glassBorder (white 10% opacity). Glassmorphism variant with backdrop blur. Gradient border variant.
- **Buttons**: Primary (gradient purple→pink, 12px radius, 52px height, shadow). Secondary (outlined, 12px radius). Text button.
- **Inputs**: Filled surfaceLight, 12px radius, 16px padding, glassBorder on enabled, primary on focus.
- **Touch targets**: Minimum 48x48dp.

### Motion
- Quick: 200ms (toggles, state changes)
- Standard: 300ms (card appearances, slide transitions)
- Slow: 500ms (page transitions)
- Reveal: 800ms (chart reveal, staggered animations)
- Easing: easeOutCubic for entrances

---

## 4. Architecture Summary

### Flutter (Frontend)
- **State management**: Riverpod 2.0 (type-safe, testable, scalable)
- **Routing**: GoRouter with auth redirect guards
- **API**: Dio with auth interceptor, error mapping, retry logic
- **Auth**: Firebase Auth (Apple, Google, Email)
- **Subscriptions**: RevenueCat Flutter SDK
- **Local storage**: SharedPreferences (settings), Hive (offline cache)
- **Error handling**: Result<T> sealed class pattern

### Go (Backend)
- **Router**: Chi v5 with middleware chain
- **Database**: PostgreSQL via sqlx + pgx
- **Cache**: Redis for rate limiting, API response caching
- **Auth**: Firebase Admin SDK token verification
- **AI**: OpenAI GPT-4o with JSON mode for structured responses
- **Subscriptions**: RevenueCat webhooks
- **Background jobs**: Worker packages with cron scheduling
- **Logging**: Structured slog (JSON in production)

---

## 5. API Contract

### Base URL
`/api/v1`

### Auth
All protected endpoints require: `Authorization: Bearer <firebase-id-token>`

### Error Shape
```json
{"error": {"code": "string", "message": "string"}}
```

### Rate Limits
- Free: 60 req/min general, 10 req/min AI chat
- Premium: 120 req/min general, 60 req/min AI chat

### Endpoints

| Method | Path | Auth | Premium | Description |
|--------|------|------|---------|-------------|
| POST | /auth/session | No | No | Bootstrap session |
| GET | /users/me | Yes | No | Get current user |
| PUT | /users/me | Yes | No | Update profile |
| DELETE | /users/me | Yes | No | Delete account |
| POST | /users/me/birth-profile | Yes | No | Save birth data |
| PUT | /users/me/birth-profile | Yes | No | Update birth data |
| GET | /users/me/preferences | Yes | No | Get preferences |
| PUT | /users/me/preferences | Yes | No | Update preferences |
| GET | /chart | Yes | Partial | Get natal chart |
| GET | /chart/summary | Yes | No | Sun/Moon/Rising |
| GET | /daily-reading | Yes | Partial | Today's reading |
| GET | /daily-reading/{date} | Yes | Yes | Historical reading |
| GET | /ai/threads | Yes | No | List chat threads |
| POST | /ai/threads | Yes | No | Create thread |
| GET | /ai/threads/{id}/messages | Yes | No | Get messages |
| POST | /ai/threads/{id}/messages | Yes | Limit | Send message |
| GET | /people | Yes | No | List saved people |
| POST | /people | Yes | No | Add person |
| DELETE | /people/{id} | Yes | No | Remove person |
| GET | /people/{id}/compatibility | Yes | Partial | Get report |
| POST | /people/{id}/compatibility | Yes | Yes | Generate report |
| GET | /timeline?type=30d\|3m\|12m | Yes | Yes | Timeline forecast |
| GET | /forecast/yearly | Yes | Yes | Yearly forecast |
| GET | /rituals/today | Yes | Yes | Today's rituals |
| POST | /rituals/{type}/complete | Yes | Yes | Complete ritual |
| GET | /journal | Yes | Yes | List entries |
| POST | /journal | Yes | Yes | Create entry |
| PUT | /journal/{id} | Yes | Yes | Update entry |
| GET | /notifications/preferences | Yes | No | Get notif prefs |
| PUT | /notifications/preferences | Yes | No | Update notif prefs |
| GET | /subscription/status | Yes | No | Subscription info |
| POST | /subscription/webhook | No | No | RevenueCat webhook |
| GET | /legal/privacy | No | No | Privacy policy |
| GET | /legal/terms | No | No | Terms of service |

---

## 6. Scheduled Jobs

| Job | Schedule | Description |
|-----|----------|-------------|
| Daily Reading Generation | 2 AM per timezone batch | Pre-generate readings for active users |
| Push Notifications | Every 15 min | Send at each user's preferred time in their timezone |
| Forecast Precomputation | Weekly (Sunday 3 AM) | Generate timeline/yearly forecasts |
| Subscription Sync | Every 6 hours | Verify RevenueCat entitlements |
| Stale Cache Cleanup | Daily 3 AM | Purge old Redis keys, notification logs, soft-deleted users |

---

## 7. Monetization

### Paywall Timing
1. After chart reveal (emotional peak)
2. When tapping premium-gated content (love, career sections)
3. After 3rd AI chat message (soft gate)
4. When trying to access full compatibility or timeline

### Trial Logic
- 3-day free trial on yearly plan only
- Full premium access during trial
- Reminder push notification 24h before trial ends

### Anti-Churn
- "Win-back" push notification 3 days after cancellation
- Periodic discount offers for lapsed subscribers
- Content quality improvements based on retention cohort analysis

---

## 8. Analytics Event Taxonomy

### Key Events
- `app_opened`, `session_started`
- `auth_started(method)`, `auth_completed(method)`, `auth_failed(method, error)`
- `onboarding_step(step_number)`, `onboarding_completed`
- `paywall_viewed(trigger)`, `paywall_dismissed`, `purchase_started(plan)`, `purchase_completed(plan)`, `purchase_failed(error)`, `restore_attempted`
- `daily_reading_viewed`, `daily_reading_shared`
- `chat_message_sent`, `chat_thread_created`, `chat_limit_hit`
- `compatibility_person_added`, `compatibility_report_viewed`, `compatibility_shared`
- `timeline_viewed(type)`, `yearly_forecast_viewed`
- `ritual_completed(type)`, `journal_entry_created`
- `notification_received`, `notification_opened`
- `settings_opened`, `account_deleted`

### Funnels
1. Install → Auth → Onboarding Complete → Paywall View → Purchase
2. Daily Open → Reading View → Chat / Compatibility / Timeline
3. Free User → Limit Hit → Paywall → Convert

### Retention Metrics
- D1, D7, D30 retention
- Weekly active users
- Streak length distribution
- Daily reading completion rate

### Revenue Metrics
- MRR, ARR
- Trial-to-paid conversion rate
- Churn rate (monthly)
- LTV by acquisition cohort

---

## 9. QA + Testing

### Automated Testing Strategy
- **Flutter**: Unit tests for providers/services, widget tests for key screens, integration tests for onboarding + paywall flow
- **Go**: Table-driven unit tests for handlers and services, repository tests against test database, integration tests for full API flows

### Manual QA Checklist
- [ ] Fresh install → auth → full onboarding → chart reveal
- [ ] Unknown birth time flow end-to-end
- [ ] Free tier limits enforced (chat, content gating)
- [ ] Purchase flow (monthly, yearly, trial)
- [ ] Restore purchases
- [ ] Offline behavior (cached content shown, graceful errors)
- [ ] Push notification delivery at correct timezone
- [ ] Account deletion (data removed, auth cleared)
- [ ] Deep links work correctly
- [ ] App survives backgrounding/foregrounding
- [ ] Accessibility: VoiceOver/TalkBack navigation

### Edge Cases
- User denies location/notification permissions
- Astrology API timeout → show cached or fallback content
- OpenAI rate limit → queue and retry, show "generating..." state
- RevenueCat webhook delay → poll on app open
- Birth time toggle mid-onboarding
- Empty states for all lists (threads, people, journal, timeline)

---

## 10. DevOps + Deployment

### Docker
- Multi-stage Go build (builder + alpine final)
- docker-compose for local dev (api + postgres + redis)
- Health checks on all services

### Environment Variables
See `.env.example` in go_backend for full list.

### Secrets Handling
- Never commit secrets to git
- Use environment variables injected at deploy time
- Firebase credentials as a mounted file, not inline
- OpenAI key, RevenueCat secret via secret manager (AWS Secrets Manager, GCP Secret Manager, or Vault)

### CI/CD Suggestion
- GitHub Actions: lint → test → build → push Docker image → deploy
- Staging deploys on PR merge to `develop`
- Production deploys on tagged releases from `main`
- Run database migrations as a pre-deploy step

### Monitoring
- Structured JSON logs → aggregation (CloudWatch, Datadog, or Loki)
- Health check endpoint at `/health`
- Alert on: API error rate > 1%, p99 latency > 2s, AI provider errors
- RevenueCat dashboard for subscription metrics

---

## 11. Legal + Compliance

### Required Screens
- Privacy Policy (scrollable, versioned, link to web version)
- Terms of Service (scrollable, versioned)
- Both must be accessible before sign-up and from Settings

### Subscription Compliance (Apple/Google)
- Show price clearly before purchase
- "Cancel anytime" messaging
- Restore Purchases button on paywall
- Auto-renewal terms near the subscribe button
- Link to manage subscription in Settings

### Privacy / GDPR
- Collect only necessary data
- Provide data export on request
- Account deletion must remove all personal data within 30 days
- Do not sell personal data to third parties
- Disclose AI processing (OpenAI) in privacy policy

### Disclaimer Strategy
- Astrology content is "for entertainment and self-reflection purposes"
- Not a substitute for professional advice
- Include in Terms of Service and as subtle footer on reading screens
- AI chat should refuse medical/financial/legal advice and redirect to professionals

---

## 12. Launch Readiness Checklist

- [ ] App Store screenshots (6.7" and 5.5" iPhone, iPad optional)
- [ ] App Store description with keywords
- [ ] Privacy policy URL hosted on web
- [ ] Terms of service URL hosted on web
- [ ] Support URL / email configured
- [ ] App Review notes explaining subscription features
- [ ] Test account credentials for App Review team
- [ ] Firebase project configured (Auth, FCM)
- [ ] RevenueCat products configured in App Store Connect / Google Play Console
- [ ] Backend deployed to staging and production
- [ ] Database migrations applied
- [ ] SSL certificate on API domain
- [ ] Push notification certificates configured
- [ ] Analytics SDK integrated and events verified
- [ ] Crash reporting configured (Firebase Crashlytics)
- [ ] Rate limiting tested under load
- [ ] All edge cases from QA checklist verified

---

*This blueprint is a complete team handoff document for Cosmic Mirror. Use the Flutter and Go scaffolding in this repository as the implementation starting point.*
