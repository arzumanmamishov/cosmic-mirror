"use client";

import { motion } from "framer-motion";
import { SectionShell } from "./SectionShell";

const features = [
  {
    title: "Western birth chart",
    desc: "Full natal wheel with planets, houses, and aspects — the classic map of who you are.",
    glyph: "♈︎",
    accent: "from-amber-300/20 to-amber-500/5",
  },
  {
    title: "Vedic / Jyotish",
    desc: "Sidereal kundli, 16 vargas, dasha periods, yogas, and shadbala — full Indian astrology.",
    glyph: "ॐ",
    accent: "from-rose-400/20 to-rose-600/5",
  },
  {
    title: "Numerology",
    desc: "Pythagorean life path, expression, soul urge, cycles, karmic lessons — and a name calculator.",
    glyph: "9",
    accent: "from-violet-400/20 to-violet-600/5",
  },
  {
    title: "Human Design",
    desc: "Type, strategy, authority, profile, channels, gates, and the iconic body graph.",
    glyph: "✦",
    accent: "from-teal-400/20 to-teal-600/5",
  },
  {
    title: "AI astrologer",
    desc: "A personal chat that knows your chart and answers in plain language, in your tongue.",
    glyph: "✶",
    accent: "from-sky-400/20 to-sky-600/5",
  },
  {
    title: "Daily reading",
    desc: "A short, personalised forecast each morning — energy, love, work, caution, an affirmation.",
    glyph: "☀",
    accent: "from-yellow-300/20 to-yellow-500/5",
  },
  {
    title: "Compatibility",
    desc: "Synastry between you and anyone — partner, family, crush. Score plus written report.",
    glyph: "♥",
    accent: "from-pink-400/20 to-pink-600/5",
  },
  {
    title: "Cosmic timeline",
    desc: "Map life moments against the sky. See exactly which transits were active when.",
    glyph: "↻",
    accent: "from-emerald-400/20 to-emerald-600/5",
  },
];

export function FeatureGrid() {
  return (
    <SectionShell
      id="features"
      eyebrow="One app, every system"
      title={
        <>
          The only spiritual toolkit
          <br />
          you actually <span className="text-gold-gradient">need</span>.
        </>
      }
      blurb="Most apps pick one tradition. Lively gives you the full set — Western, Vedic, numerology, Human Design — bound together by a chart-aware AI and a community of fellow seekers."
    >
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {features.map((f, i) => (
          <motion.div
            key={f.title}
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, amount: 0.4 }}
            transition={{ duration: 0.5, delay: i * 0.05 }}
            className="glass relative overflow-hidden rounded-2xl p-5 transition-all hover:-translate-y-1 hover:border-gold/30 hover:shadow-gold-glow"
          >
            <div
              className={`pointer-events-none absolute inset-0 bg-gradient-to-br ${f.accent} opacity-60`}
            />
            <div className="relative">
              <div className="grid h-11 w-11 place-items-center rounded-xl bg-gold/15 font-display text-xl text-gold">
                {f.glyph}
              </div>
              <h3 className="mt-4 font-display text-lg font-bold">
                {f.title}
              </h3>
              <p className="mt-2 text-sm leading-relaxed text-cosmic-muted">
                {f.desc}
              </p>
            </div>
          </motion.div>
        ))}
      </div>
    </SectionShell>
  );
}
