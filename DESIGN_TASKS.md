# Lively — Design Tasks

A handoff document for redesigning the **Lively** app (Flutter astrology app —
Western / Vedic / Numerology / Human Design). Hand individual tasks below to
Claude Design (or any designer) to make the app more attractive.

---

## Shared context — include this with every task

> **App:** "Lively" — a Flutter astrology app covering Western charts, Vedic
> (Jyotish), Numerology, and Human Design, plus an AI astrologer chat, a
> community forum, journaling, and compatibility readings.
>
> **Theming:** Dark cosmic theme **and** an iOS-style light theme. Both are
> driven by an `AppPalette` ThemeExtension
> (`flutter_app/lib/config/theme/app_palette.dart`). **Every task must keep
> both themes working** — never hardcode colors, always use palette tokens
> (`p.background`, `p.surface`, `p.primary`, `p.accent`, `p.gold`,
> `p.textPrimary`, `p.textSecondary`, `p.glassBorder`, `p.primaryGradient`,
> energy colors `p.success / p.warning / p.error`, etc.).
>
> **Brand:** accent is a bronze-gold `#D4B16A`. The wordmark is "Lively"; the
> logo lives at `flutter_app/assets/` (`lively_logo.png`). Tone: warm,
> modern, premium, emotionally intelligent — not mystical-kitsch.
>
> **Constraints:**
> - Text form fields should use the **same color as the page background**
>   (established preference — no contrasting fill).
> - Message bubbles and surfaces use **solid colors only** where specified —
>   no gradients on chat bubbles.
> - Localized for English + Turkish (`flutter_app/lib/l10n/`), so designs must
>   tolerate ~30% longer strings.
> - Material 3 + Flutter; reuse existing shared widgets where possible.

---

## Page inventory (41 screens)

### Auth & Onboarding
- **Auth** — login / register, social sign-in, forgot-password dialog.
- **Onboarding Flow** — 5-step birth data capture (name, date, time, place, focus areas).
- **Welcome** — post-onboarding celebration / chart reveal.

### Home — 4 bottom-nav tabs
- **Discover** — daily reading card, quick actions, feed.
- **Charts** — grid of feature cards (Birth Chart, Vedic, Numerology, Human Design, Transit Forecast, Yearly Forecast).
- **Chat** — AI astrologer thread list.
- **Community** — embedded spaces hub.

### Charts & Readings (10)
- **Birth Chart** — Western natal chart wheel + planets / houses / aspects tabs.
- **Vedic Chart** — North-Indian chart, vargas, dasha, yogas.
- **Human Design** — 9-center body graph, type / strategy / authority / profile.
- **Numerology** — core numbers, lifelong cycles, karmic patterns.
- **Numerology Compatibility** — two-person numerology score.
- **Numerology Name Calculator** — analyze any name.
- **Daily Reading** — personalized daily horoscope.
- **Transit Forecast (Timeline)** — 30d / 3m / 12m transit periods.
- **Yearly Forecast** — 4-quarter year narrative.
- **Life Timeline** — personal life-events timeline + add-event sheet.

### AI Chat (2)
- **Chat Threads** — conversation list.
- **Chat** — conversation view.

### Compatibility (3)
- **Compatibility** — saved-people list.
- **Add Person** — input form for a new comparison.
- **Compatibility Report** — score rings + breakdown.

### Journal & Rituals (3)
- **Journal** — entry list.
- **Journal Entry** — entry editor.
- **Rituals** — guided rituals.

### Profile & Settings (3)
- **Profile** — astrology bio, stats, premium status.
- **Edit Birth Data** — change birth date / time / place.
- **Settings** — language, theme, account, developer options.

### Community (12)
- **Spaces List** — community hub.
- **Space Detail** — single space (with locked / pending content states).
- **Create Space** / **Edit Space**.
- **Members** — approved member list.
- **Join Requests** — owner-only approval inbox.
- **Post Detail** — post + comments.
- **Compose Post** — bottom sheet.
- **Category Detail** — spaces in a category.
- **Hashtag Feed** — posts under a hashtag.
- **Community Profile** — a user's joined spaces + recent posts.
- **Notifications** — activity feed.

### Monetization (1)
- **Paywall** — premium subscription upsell.

---

## Design tasks

### Task 1 — First-impression flow
Redesign **Auth**, **Onboarding Flow**, and **Welcome**. These set the tone —
make them feel premium and calming. Onboarding has 5 steps
(name / date / time / place / focus); make step transitions delightful, add a
clear progress affordance, and reduce form fatigue. Welcome should feel like a
genuine payoff moment when the user's chart is first revealed.

### Task 2 — Home Discover tab
Redesign the **Discover** tab — the screen users see most. Hero daily-reading
card, quick-action shortcuts, cosmic backdrop. Make it scannable and alive
without clutter. Establish the visual rhythm the rest of the app borrows from.

### Task 3 — Charts grid + core chart screens
Unify the **Charts** tab grid and the 5 calculation screens (**Birth Chart**,
**Vedic Chart**, **Human Design**, **Numerology**, **Daily Reading**). They each
render data-dense content (wheels, body graphs, number cards). Establish a
consistent "result page" layout: hero summary → tabbed detail. The Human Design
body graph and the natal wheel are `CustomPainter` widgets — give art
direction for them, not just surrounding layout.

### Task 4 — Forecast screens
Redesign **Transit Forecast**, **Yearly Forecast**, and **Life Timeline**. All
three are time-based narratives. Create a shared visual language for "periods" —
energy-coded (positive / challenging / intense / neutral), seasonal cues, and a
timeline rail.

### Task 5 — AI Chat
Polish the **Chat Threads** list and the **Chat** conversation view. Message
bubbles use solid colors only (no gradients). Make the empty state and the
suggested-prompts inviting — the AI persona is a "warm, funny friend who
happens to know astrology," so the UI should feel conversational, not clinical.

### Task 6 — Community
Redesign the 12 **Community** screens as a cohesive sub-app: spaces hub, space
detail (with the locked / pending content states for non-members), join-requests
inbox, post detail, profiles, notifications. Make it feel social and warm,
distinct from the astrology screens but still on-brand.

### Task 7 — Compatibility
Redesign the compatibility flow (**Compatibility** list → **Add Person** →
**Compatibility Report**). The report has score rings + breakdown sections —
make it emotionally resonant and shareable.

### Task 8 — Journal & Rituals
Redesign **Journal** (list + entry editor) and **Rituals**. These should feel
like a quiet, personal space — softer and more intimate than the data screens.

### Task 9 — Profile, Settings, Paywall
Redesign **Profile**, **Edit Birth Data**, **Settings**, and **Paywall**.
Paywall is revenue-critical — make the premium value obvious and the CTA
confident without being pushy.

### Task 10 — Design system pass
Before or alongside the above: audit `AppPalette` and the shared widgets
(cards, buttons, error views, loading shimmers, bottom nav). Define a spacing
scale, type ramp, elevation rules, and motion guidelines so all 41 screens
stay consistent. This task feeds all the others — ideally do it first.

---

## Suggested order

1. **Task 10** (design system) — sets the foundation.
2. **Task 1** (first impression) — highest-leverage for new users.
3. **Task 2** (Discover) — most-seen screen.
4. **Task 3** (charts) — the core product value.
5. **Tasks 4–9** — in any order, by priority.
