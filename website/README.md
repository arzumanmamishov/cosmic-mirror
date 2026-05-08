# Lively — Marketing Website

The first-impression site for the Lively app. A single-page Next.js + Tailwind
build with Framer Motion entrance animations, mirroring the app's cosmic-gold
theme so users flow visually from the site straight into the app.

## Stack

- **Next.js 14** (App Router) — fast, SEO-friendly, easy Vercel deploy.
- **Tailwind CSS** — design tokens (`cosmic-bg`, `gold`, etc.) mirror the
  Flutter app's `AppPalette`.
- **Framer Motion** — scroll-revealed entrance animations on every section.
- **Pure SVG** for the natal wheel, North-Indian diamond, body graph, and
  phone mock — no real screenshots needed to look finished.

## Local dev

```bash
cd website
npm install
npm run dev
# open http://localhost:3000
```

## Build

```bash
npm run build
npm run start
```

## Deploy

The site is a stock Next.js app, so any of these work:

- **Vercel** (recommended, zero-config): `vercel --prod`. Vercel detects
  Next.js automatically.
- **Netlify** (`@netlify/plugin-nextjs`): point at the `website/` folder.
- **Self-host**: `npm run build && npm run start` behind any reverse proxy.

## Sections

In order of scroll:

1. `Nav` — sticky, frosts on scroll
2. `Hero` — headline + store CTAs + animated phone mock
3. `FeatureGrid` — 8 high-level features
4. `ChartShowcase` — Western birth chart + decorative natal wheel
5. `VedicShowcase` — sidereal kundli + North-Indian diamond
6. `NumerologyShowcase` — six core numbers + cycles teaser
7. `HumanDesignShowcase` — type/strategy + body graph artwork
8. `AIAstrologer` — sample conversation + stat panels
9. `Compatibility` — synastry score card + features
10. `Timeline` — three life events tied to transits
11. `JournalAndRituals` — three daily-practice cards
12. `Community` — six example spaces
13. `Languages` — EN + TR live, others "soon"
14. `Pricing` — Free vs Premium tier cards
15. `DownloadCTA` — final big push to App Store / Play
16. `Footer` — link groups + socials + legal

## Editing

- **Theme tokens** live in `tailwind.config.ts` (cosmic + gold + accents).
- **Section copy** is defined inline in each `src/components/*.tsx` file —
  no CMS needed.
- **Replace SVG placeholders** with real screenshots when you have them:
  drop PNGs into `public/` and swap the `PhoneMock` / wheel / diamond /
  body-graph artwork components.

## License

Proprietary — same terms as the parent repo.
