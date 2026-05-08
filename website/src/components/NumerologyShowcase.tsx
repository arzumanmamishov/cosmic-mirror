"use client";

import { SectionShell } from "./SectionShell";

const numbers = [
  { label: "Life Path", value: "11", master: true, desc: "Visionary intuition · spiritual messenger" },
  { label: "Expression", value: "7", desc: "Seeker of depth · pattern-recognizer" },
  { label: "Soul Urge", value: "5", desc: "Hunger for freedom · transformative motion" },
  { label: "Personality", value: "8", desc: "Reads as composed authority" },
  { label: "Maturity", value: "9", desc: "Wisdom you'll grow into" },
  { label: "Birthday", value: "22", master: true, desc: "Master Builder of the practical" },
];

export function NumerologyShowcase() {
  return (
    <SectionShell
      eyebrow="Numerology"
      title={
        <>
          Six core numbers,
          <br />
          <span className="text-gold-gradient">decoded</span>.
        </>
      }
      blurb="Pythagorean numerology with everything serious readers expect — master numbers (11/22/33), karmic debt (13/14/16/19), karmic lessons, hidden passion, four pinnacle cycles, four challenge cycles, and personal year/month/day. Plus: type any name into the calculator to see its breakdown."
    >
      <div className="grid gap-4 md:grid-cols-3">
        {numbers.map((n) => (
          <div
            key={n.label}
            className="glass relative overflow-hidden rounded-2xl p-6"
          >
            {n.master && (
              <span className="absolute right-3 top-3 rounded-full bg-gold/15 px-2 py-0.5 text-[9px] font-black uppercase tracking-wider text-gold">
                Master
              </span>
            )}
            <div className="text-xs font-bold uppercase tracking-wider text-cosmic-dim">
              {n.label}
            </div>
            <div className="mt-2 font-display text-6xl font-black text-gold-gradient leading-none">
              {n.value}
            </div>
            <div className="mt-3 text-sm text-cosmic-muted">{n.desc}</div>
          </div>
        ))}
      </div>

      {/* Pinnacle / Challenge cycle teaser */}
      <div className="mt-12 grid gap-6 rounded-3xl border border-white/10 bg-white/5 p-6 md:grid-cols-2 md:p-10">
        <div>
          <div className="text-xs font-bold uppercase tracking-wider text-gold">
            Lifelong cycles
          </div>
          <h3 className="mt-2 font-display text-2xl font-extrabold">
            Four pinnacles. Four challenges. Mapped to your age.
          </h3>
          <p className="mt-3 text-cosmic-muted">
            We compute your four lifelong pinnacle cycles and four challenge
            cycles, highlighting which one is currently active so you know
            exactly what life is teaching you right now.
          </p>
        </div>
        <CyclesArt />
      </div>
    </SectionShell>
  );
}

function CyclesArt() {
  const ages = [0, 27, 36, 45, 54];
  const labels = ["P1 · 7", "P2 · 3", "P3 · 11", "P4 · 5"];
  return (
    <div className="rounded-2xl border border-white/10 bg-cosmic-bg/60 p-5">
      <div className="relative mt-3 h-20">
        <div className="absolute left-0 right-0 top-1/2 h-px -translate-y-1/2 bg-white/10" />
        {ages.map((a, i) => (
          <div
            key={a}
            className="absolute -translate-x-1/2 -translate-y-1/2 text-[10px] text-cosmic-dim"
            style={{ left: `${(a / 80) * 100}%`, top: "50%" }}
          >
            <span className="block translate-y-7">age {a}</span>
            <span className="mx-auto block h-2 w-2 rounded-full bg-gold" />
          </div>
        ))}
        {labels.map((l, i) => {
          const left = ((ages[i] + ages[i + 1]) / 2 / 80) * 100;
          return (
            <div
              key={l}
              className={`absolute -translate-x-1/2 -translate-y-full rounded-md px-2 py-0.5 text-[10px] font-bold ${
                i === 1
                  ? "bg-gold-gradient text-[#1a1f2e]"
                  : "border border-white/10 text-cosmic-muted"
              }`}
              style={{ left: `${left}%`, top: "50%" }}
            >
              {l}
            </div>
          );
        })}
      </div>
    </div>
  );
}
