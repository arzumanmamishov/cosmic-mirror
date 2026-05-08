"use client";

import { SectionShell } from "./SectionShell";

const events = [
  {
    date: "Mar 2024",
    title: "Started a new chapter",
    transit: "Saturn return at 0° Pisces · Jupiter trine natal Sun",
    color: "#5CC9C0",
  },
  {
    date: "Aug 2023",
    title: "Met someone unexpected",
    transit: "Venus conjunct natal Mars · Solar eclipse in 7th house",
    color: "#E14B8A",
  },
  {
    date: "Jan 2022",
    title: "Career break",
    transit: "Pluto squared natal MC · Lunar eclipse in 10th",
    color: "#F4C542",
  },
];

export function Timeline() {
  return (
    <SectionShell
      eyebrow="Cosmic Timeline"
      title={
        <>
          Your life, mapped against the
          <br />
          <span className="text-gold-gradient">sky</span>.
        </>
      }
      blurb="Add the moments that mattered — births, breakups, big moves, breakthroughs. Lively shows you exactly which transits were active, so the patterns of your life become visible. The longer you use it, the more irreplaceable it becomes."
    >
      <div className="relative mx-auto max-w-2xl">
        <div className="absolute bottom-0 left-6 top-0 w-px bg-gradient-to-b from-gold/0 via-gold/40 to-gold/0 md:left-8" />
        <div className="space-y-8">
          {events.map((e, i) => (
            <div key={i} className="relative flex gap-6 pl-12 md:pl-16">
              <div
                className="absolute left-3 top-2 h-6 w-6 rounded-full border-4 border-cosmic-bg ring-2 md:left-5"
                style={{ background: e.color, boxShadow: `0 0 16px ${e.color}66` }}
              />
              <div className="flex-1 rounded-2xl border border-white/10 bg-white/5 p-5">
                <div className="flex flex-wrap items-baseline justify-between gap-2">
                  <div className="font-display text-lg font-bold text-cosmic-text">
                    {e.title}
                  </div>
                  <div className="text-xs text-cosmic-dim">{e.date}</div>
                </div>
                <div className="mt-3 rounded-lg border border-gold/20 bg-gold/5 px-3 py-2 text-xs text-gold">
                  ✦ {e.transit}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </SectionShell>
  );
}
