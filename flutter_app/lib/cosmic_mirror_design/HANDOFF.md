# Lively — Design Handoff

Implementation guide for **Task 1 (Auth · Onboarding · Welcome)** and the **Design System foundation (Task 10)**.

This document is written for Claude Code in VS Code. Open this folder, open `Lively Redesign.html`, and work through the tasks below.

---

## What's in the package

| File | Purpose |
|---|---|
| `Lively Redesign.html` | Master file — open this for the full canvas |
| `lively-tokens.jsx` | Design system: palette, type, spacing, radius |
| `lively-components.jsx` | Shared primitives: backdrop, button, field, chip, mini wheel |
| `lively-screens.jsx` | Auth, Name, Date, Time |
| `lively-screens2.jsx` | Place, Focus, Welcome |
| `lively-flow.jsx` | Interactive prototype (Dark+Light side-by-side) |
| `lively-app.jsx` | Root: design canvas layout |
| `design-canvas.jsx`, `ios-frame.jsx`, `android-frame.jsx`, `tweaks-panel.jsx` | Starter scaffolds |

Run with any static server (`python -m http.server`, Live Server, etc).

---

## Design tokens → `AppPalette`

Add to `flutter_app/lib/config/theme/app_palette.dart`. Both themes must define every token.

### Dark · Cosmic

| Token | Value |
|---|---|
| `background` | `#08080F` |
| `bgDeep` | `#050509` |
| `surface` | `#13131C` |
| `surfaceHi` | `#1B1B27` |
| `line` | `rgba(255,255,255,0.08)` |
| `glassBorder` | `rgba(212,177,106,0.22)` |
| `primary` | `#D4B16A` |
| `primaryHi` | `#E8C988` |
| `primaryDim` | `#9C8049` |
| `onPrimary` | `#1A1408` |
| `text` / `textPrimary` | `#F2EBD9` |
| `textSecondary` / `textMuted` | `#A09989` |
| `textDim` | `#6A6358` |
| `success` | `#7FB686` |
| `warning` | `#E0A86E` |
| `error` | `#D87575` |
| `primaryGradient` | radial `#1F2547` → `#11132A` → `#08080F` |

### Light · iOS

| Token | Value |
|---|---|
| `background` | `#FBF7EE` |
| `bgDeep` | `#F4EFE2` |
| `surface` | `#FFFFFF` |
| `line` | `rgba(26,22,16,0.08)` |
| `glassBorder` | `rgba(168,133,70,0.25)` |
| `primary` | `#A88546` |
| `primaryHi` | `#C09957` |
| `onPrimary` | `#FFFBF1` |
| `text` / `textPrimary` | `#1A1610` |
| `textSecondary` | `#6B6259` |
| `success` | `#5C8E66` |
| `warning` | `#B57F3C` |
| `error` | `#B85555` |
| `primaryGradient` | radial `#F0E5CC` → `#F8F0DD` → `#FBF7EE` |

> The gold `#D4B16A` from the brief is the **dark-theme** value. On light it shifts to `#A88546` for AA contrast.

---

## Typography

Add to `pubspec.yaml` and bundle as Flutter fonts.

| Role | Family | Use |
|---|---|---|
| Display | **Instrument Serif** (italic) | Hero titles, section headers, emotional moments |
| UI | **Geist** | Buttons, labels, body, forms |
| Mono | **Geist Mono** | Coordinates, timestamps, code-ish micro-copy |

### Type scale

| Token | Size · Line · Weight · Family |
|---|---|
| `d1` | 56 / 60 · 400 · Instrument Serif italic |
| `d2` | 42 / 46 · 400 · Instrument Serif italic |
| `d3` | 32 / 36 · 400 · Instrument Serif italic |
| `h1` | 22 / 28 · 500 · Geist |
| `h2` | 17 / 22 · 500 · Geist |
| `body` | 15 / 22 · 400 · Geist |
| `small` | 13 / 18 · 400 · Geist |
| `caption` | 11 / 14 · 500 · Geist · letter-spacing 0.06em uppercase |

Letter spacing on display tokens: `-0.02em` (d1), `-0.015em` (d2), `-0.01em` (d3).

---

## Spacing & radius

```dart
class LivelySpace { static const xs=4, sm=8, md=12, lg=16, xl=24, xl2=32, xl3=48, xl4=64; }
class LivelyRadius { static const sm=8, md=12, lg=16, xl=20, xl2=28; }
```

---

## Shared components — wire these first

> Build these in `lib/widgets/lively/` before touching screens. Every screen below assumes they exist.

### `LivelyBackdrop`
Radial cosmic gradient + sparse starfield. Deterministic seed (don't regenerate per build). On dark, a faint primary-tinted aurora ellipse drifts at top (7s loop). Skip the aurora on light.

### `LivelyMark`
8-point bronze sparkle inside a thin gold ring. Sizes: 26 (compact) / 32 (hero).

### `LivelyWordmark`
"Lively" in Instrument Serif italic. Default 22px.

### `GoldButton`
- Pill, radius 999, padding 15×22 (small variant 11×18)
- Bg: `palette.primary`, fg: `palette.onPrimary`
- Inner top-highlight: `inset 0 1px 0 primaryHi`
- Outer glow: `0 8px 24px rgba(212,177,106,0.18)` (dark) / `rgba(168,133,70,0.2)` (light)
- `:active` → scale 0.97 (80ms ease)
- Ghost variant: transparent bg, 1px glassBorder, primary fg

### `FormField`
Fill = **page background** (per brief — no contrasting fill). Border `palette.line` → on focus, `palette.primary` 1px + `0 0 0 3px primary @ 13% alpha` glow. Radius 14. Label above in caption style.

### `Chip`
Selectable. Idle: `surfaceGlass`, `line` border. Selected: primary @ 14% alpha bg, primary border + text. Icon left, label right.

### `StepProgress`
5-segment rail. Each segment 6px tall, radius 999. Inactive: `palette.line`. Done/Active: `palette.primary`. **Active segment is wider** (22px) than the rest (6px). Animate width on step change (250ms cubic-bezier).

### `MiniWheel`
SVG-equivalent in Flutter `CustomPainter`:
- Outer ring + inner ring, both `primary @ ~50% alpha`, hair-thin
- 12 tick lines between rings
- Center radial gradient `primary @ 8% → transparent` for the soft glow
- Three luminary medallions (Sun / Moon / Rising) — small bronze-bordered circles holding the unicode zodiac glyph, placed at -60°, +75°, +180°
- Used at 220px in Welcome

---

## Per-screen implementation

### Auth (`lib/screens/auth/auth_screen.dart`)

- Full-bleed `LivelyBackdrop`, `seed: 11`
- Top-left: `LivelyMark` + `LivelyWordmark` (small)
- Hero block (top ~30%):
  - Kicker: "Welcome back" caption-style, primary color, letter-spacing 0.18em
  - Title: `d2` "The sky, made personal." (italic, two lines)
  - Sub: body, textMuted, max-width 280
- Form block (bottom ~40%):
  - Email field
  - Password field with **"Forgot"** trailing link (primary, 12px, weight 500)
  - 14px gap → `GoldButton "Continue"` full-width
  - Divider "or" (10px caption, 1px line each side)
  - Apple + Google buttons, side-by-side, 13px padding, `line` border, surface bg
  - Footer: "New to Lively? **Create account**" (primary link)

### Onboarding shell (shared layout for steps 1–5)

```
┌─ Back chip · StepProgress · "N / 5" ┐
│                                     │
│ KICKER                              │
│ Title (d3 italic, 2 lines)          │
│ Subtitle (body, textMuted, max 300) │
│                                     │
│ {step body}                         │
│                                     │
│ [tertiary action]                   │
│ Continue → (GoldButton)             │
└─────────────────────────────────────┘
```

Back chip: 32×32 circle, `line` border, surface-tinted bg, chevron icon.

### 01 · Name
Single `FormField` (large variant, 18px content, 18×18 padding). Below: small textMuted reassurance "We'll never share this."

### 02 · Date
3-column wheel picker (Month · Day · Year). Center band: 44px tall, `primary @ 10% alpha`, `glassBorder`. Items: size 22, weight 600 active (primary color), 400 inactive, opacity falls off 0.28 per step from center, scale 0.93/0.86 at ±1/±2. Column footers: 10px uppercase caption labels.

### 03 · Time
Same wheel pattern (Hour · Min · AM/PM). Below the picker: a small `glassBorder` info card with sparkle icon explaining why birth time matters (4 minutes ≈ one Ascendant sign). Tertiary action below CTA: "I don't know · **Use sunrise**".

### 04 · Place
- Search field (with map-pin prefix icon)
- Results list (`surface` card, 1px line dividers):
  - Each row: small map-pin avatar (selected → primary fill), city · country sub, GMT offset right (mono)
- Below: "Coordinates" card with lat/long in mono + a tiny SVG "horizon arc" (curve over dotted horizon line, sun dot above)

### 05 · Focus
- 2-column chip grid, 6 chips: Love & relationships · Career & purpose · Self-knowledge · Spirituality · Growth & change · Big life questions
- "Pick up to 3" — selection counter below grid in textMuted
- CTA label changes to **"See my chart"**

### Welcome (`lib/screens/welcome/welcome_screen.dart`)

The payoff. Staggered reveal — the whole screen builds itself in front of the user.

```
✨ WELCOME, ALEX
JULY 28, 1996 · 10:31 AM · ISTANBUL

Your chart
is ready.        ← "is ready." in primary gold

   (mini wheel)

[ SUN ] [ MOON ] [ RISING ]
[ Leo ] [Pisces] [Scorpio ]

A Leo sun in a Scorpio house —
you live loudly, but you choose carefully.

[ Enter Lively → ]
```

**Reveal stagger** (all use the lively-rise keyframe: `from { opacity:0; y:8px } to { opacity:1; y:0 }`, 700ms ease-out):

| Element | Delay |
|---|---|
| Kicker + date line | 0ms |
| "Your chart is ready." | 150ms |
| Mini wheel (scale-in 0.6→1, cubic-bezier .2,.9,.3,1.05, 800ms) | 350ms |
| Sun card | 900ms |
| Moon card | 1050ms |
| Rising card | 1200ms |
| Opening line italic | 1400ms |
| Enter Lively CTA | 1600ms |

---

## Motion guidelines

| Pattern | Curve | Duration |
|---|---|---|
| Screen enter (push) | cubic-bezier(.2,.7,.2,1) | 420ms |
| Screen exit | cubic-bezier(.5,0,.7,.3) | 250ms |
| StepProgress segment width | cubic-bezier(.2,.7,.3,1) | 250ms |
| Button press (scale 0.97) | ease | 80ms in / 120ms out |
| Field focus border + glow | ease | 150ms |
| Star twinkle (subset only) | ease-in-out infinite | 3.5–6s, staggered |
| Aurora drift (dark only) | ease-in-out infinite | 7s |
| Welcome chart reveal | see stagger table |

Star twinkle: not every star. Only ~30% (pre-tagged at seed time). Min opacity 40% of base, peak 160% of base, scale 1.0→1.18.

---

## Localization (TR)

All copy strings tolerate ~30% longer Turkish translations:
- Hero titles use 2 fixed lines + word-wrap fallback — never truncate.
- Chip grid is fluid 2-column; chips wrap if label runs long.
- Button labels are sized by content, not fixed-width.

Strings to add to `lib/l10n/`:

```
auth_welcome_kicker = "Welcome back"
auth_title          = "The sky, made personal."
auth_subtitle       = "Sign in to your charts, journal, and the daily reading written for you."
auth_email_label    = "Email"
auth_password_label = "Password"
auth_forgot         = "Forgot"
auth_continue       = "Continue"
auth_or             = "or"
auth_new_user       = "New to Lively?"
auth_create_account = "Create account"

onb_step_label      = "Step {n}"
onb_name_title      = "What should we call you?"
onb_name_subtitle   = "Your readings are written for a person, not a profile. First name is fine."
onb_name_reassure   = "We'll never share this. Change it any time in Profile."

onb_date_kicker     = "Step 2 · Birth date"
onb_date_title      = "When were you born?"
onb_date_subtitle   = "Your sun sign and the season of your birth start here."

onb_time_kicker     = "Step 3 · Birth time"
onb_time_title      = "And the hour?"
onb_time_subtitle   = "Your rising sign and the houses depend on the exact minute. Within 15 minutes is great."
onb_time_unknown    = "I don't know"
onb_time_use_sunrise= "Use sunrise"
onb_time_info       = "Birth certificates have it. So do most baby books. A four-minute difference can change your Ascendant by a whole sign."

onb_place_kicker    = "Step 4 · Birthplace"
onb_place_title     = "Where in the world?"
onb_place_subtitle  = "The horizon — your Ascendant — depends on the longitude and latitude of where you were born."

onb_focus_kicker    = "Step 5 · Almost there"
onb_focus_title     = "What draws you to the stars?"
onb_focus_subtitle  = "Pick up to three. Your daily reading and the AI astrologer will lean into these."
onb_focus_cta       = "See my chart"
onb_focus_love      = "Love & relationships"
onb_focus_career    = "Career & purpose"
onb_focus_self      = "Self-knowledge"
onb_focus_spirit    = "Spirituality"
onb_focus_growth    = "Growth & change"
onb_focus_questions = "Big life questions"

welcome_kicker      = "Welcome, {name}"
welcome_title       = "Your chart"
welcome_title_2     = "is ready."
welcome_sun         = "Sun"
welcome_moon        = "Moon"
welcome_rising      = "Rising"
welcome_enter       = "Enter Lively"
```

---

## Suggested build order for Claude Code

1. **Tokens** — wire `AppPalette` for both themes from the table above.
2. **Fonts** — add Instrument Serif + Geist to `pubspec.yaml`.
3. **Shared widgets** — `LivelyBackdrop`, `LivelyMark`, `LivelyWordmark`, `GoldButton`, `FormField`, `Chip`, `StepProgress` in `lib/widgets/lively/`.
4. **`MiniWheel` CustomPainter** — render to spec.
5. **Auth screen** — first visible payoff.
6. **Onboarding shell** — shared layout used by 5 steps.
7. **Steps 1 → 5** — straightforward once the shell exists.
8. **Welcome screen** — staggered reveal with `AnimationController` per element (`Interval` curve on a single 2s controller is the cleanest pattern).
9. **Wire routing** — `Auth → Onboarding stack → Welcome → Home`.

---

## Verifying against the design

Open `Lively Redesign.html`. The **Interactive prototype** section at the top shows both themes side-by-side and lets you step through the flow (▶ play to auto-advance). Use that as the reference — it's the source of truth, not the static screenshots.
