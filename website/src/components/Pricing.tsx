"use client";

import { SectionShell } from "./SectionShell";

const free = [
  "Full Western birth chart",
  "Vedic Rasi (D1) chart",
  "Six core numerology numbers",
  "Daily reading",
  "5 AI astrologer messages a day",
  "1 saved compatibility report",
  "Public community spaces",
];

const premium = [
  "Everything in Free, plus:",
  "All 16 Vedic vargas + dashas + yogas + shadbala + ashtakavarga",
  "Full Human Design body graph + variables",
  "Unlimited AI astrologer chat",
  "Unlimited compatibility reports",
  "Cosmic Timeline · 30-day, 3-month, and yearly forecasts",
  "Rituals + journal prompts tuned to your chart",
  "Ad-free everywhere",
];

export function Pricing() {
  return (
    <section id="pricing">
      <SectionShell
        align="center"
        eyebrow="Pricing"
        title={
          <>
            Try it free.
            <br />
            <span className="text-gold-gradient">Go premium</span> when you're
            hooked.
          </>
        }
        blurb="No credit card to start. Cancel anytime."
      >
        <div className="mx-auto grid max-w-4xl gap-6 md:grid-cols-2">
          <Tier
            name="Free"
            price="$0"
            unit="forever"
            cta="Download free"
            items={free}
            featured={false}
          />
          <Tier
            name="Premium"
            price="$6.99"
            unit="/month · or $39.99/year (save 52%)"
            cta="Start free trial"
            items={premium}
            featured
          />
        </div>
        <p className="mt-6 text-center text-xs text-cosmic-dim">
          Free 3-day trial on the yearly plan. Subscriptions auto-renew until
          cancelled in your app store account.
        </p>
      </SectionShell>
    </section>
  );
}

function Tier({
  name,
  price,
  unit,
  cta,
  items,
  featured,
}: {
  name: string;
  price: string;
  unit: string;
  cta: string;
  items: string[];
  featured: boolean;
}) {
  return (
    <div
      className={`relative overflow-hidden rounded-3xl border p-7 ${
        featured
          ? "border-gold/50 bg-gradient-to-b from-gold/15 to-gold/5 shadow-gold-glow"
          : "border-white/10 bg-white/5"
      }`}
    >
      {featured && (
        <span className="absolute right-5 top-5 rounded-full bg-gold-gradient px-3 py-1 text-[10px] font-black uppercase tracking-wider text-[#1a1f2e]">
          Most popular
        </span>
      )}
      <div className="text-xs uppercase tracking-wider text-cosmic-muted">
        {name}
      </div>
      <div className="mt-2 flex items-baseline gap-2">
        <span className="font-display text-5xl font-black text-cosmic-text">
          {price}
        </span>
        <span className="text-sm text-cosmic-muted">{unit}</span>
      </div>
      <a
        href="#download"
        className={`mt-5 inline-flex w-full items-center justify-center rounded-full px-5 py-3 text-sm font-bold transition-transform hover:scale-[1.02] ${
          featured
            ? "bg-gold-gradient text-[#1a1f2e] shadow-gold-glow"
            : "border border-white/15 bg-white/5 text-cosmic-text hover:border-gold/40"
        }`}
      >
        {cta}
      </a>
      <ul className="mt-6 space-y-3 text-sm">
        {items.map((it) => (
          <li key={it} className="flex items-start gap-2 text-cosmic-muted">
            <span
              className={`mt-1 grid h-4 w-4 flex-shrink-0 place-items-center rounded-full text-[8px] font-black ${
                featured ? "bg-gold-gradient text-[#1a1f2e]" : "bg-gold/15 text-gold"
              }`}
            >
              ✓
            </span>
            <span>{it}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}
