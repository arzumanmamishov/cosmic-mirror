"use client";

import { SectionShell } from "./SectionShell";

const spaces = [
  { name: "Saturn returns", members: "2.1k", desc: "The 27-30 reckoning, lived in real time." },
  { name: "Vedic readers", members: "980", desc: "Ayanamsa debates, dasha walkthroughs, kundli reviews." },
  { name: "Pisces moons", members: "1.7k", desc: "Where the dreamers gather to translate the swirl." },
  { name: "Manifestors", members: "1.3k", desc: "Inform-then-act energy, comparing notes." },
  { name: "Numerology lab", members: "640", desc: "Master numbers, karmic debt, naming futures." },
  { name: "Daily transits", members: "3.4k", desc: "What's the sky doing right now? Conversation per day." },
];

export function Community() {
  return (
    <section id="community">
      <SectionShell
        eyebrow="Community"
        title={
          <>
            Find your <span className="text-gold-gradient">people</span>.
          </>
        }
        blurb="Lively isn't a one-way feed. It's spaces you can join — by sign, by school of thought, by life moment. Post, comment, like, follow hashtags, get notified when someone replies. Quiet by default; loud only when you want it."
      >
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {spaces.map((s) => (
            <div
              key={s.name}
              className="glass group rounded-2xl p-5 transition-all hover:-translate-y-1 hover:border-gold/30"
            >
              <div className="flex items-center justify-between">
                <div className="font-display text-lg font-bold">{s.name}</div>
                <span className="rounded-full border border-white/10 bg-white/5 px-2 py-0.5 text-[10px] text-cosmic-muted">
                  {s.members}
                </span>
              </div>
              <p className="mt-2 text-sm text-cosmic-muted">{s.desc}</p>
              <div className="mt-4 flex items-center gap-2 text-xs">
                <span className="rounded-full bg-gold/15 px-2 py-0.5 font-semibold text-gold">
                  Join
                </span>
                <span className="text-cosmic-dim">→ open the space</span>
              </div>
            </div>
          ))}
        </div>
      </SectionShell>
    </section>
  );
}
