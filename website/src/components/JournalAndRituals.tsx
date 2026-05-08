"use client";

import { SectionShell } from "./SectionShell";

export function JournalAndRituals() {
  return (
    <SectionShell
      eyebrow="Journal · Daily Reading · Rituals"
      title={
        <>
          A quiet daily practice,
          <br />
          built into the <span className="text-gold-gradient">app</span>.
        </>
      }
      blurb="Lively isn't just charts. Each morning brings a personalised reading; a streak grows as you complete simple rituals; the journal gives you a cosmic-aware diary that ties what you wrote to what the sky was doing."
    >
      <div className="grid gap-6 md:grid-cols-3">
        <Card
          title="Today's Reading"
          accent="#F4C542"
          glyph="☉"
          body="A short morning forecast — energy, love, work, caution, an affirmation, lucky color, lucky number. Personal to your chart, not a generic horoscope."
          tags={["Energy: high", "Heart-forward", "Mind sharp"]}
        />
        <Card
          title="Cosmic Journal"
          accent="#7B61FF"
          glyph="✎"
          body="Write what you noticed today. Pick a mood. Or start from a prompt. Lively timestamps every entry against the sky so you can re-read them in transit-context later."
          tags={["8 prompts", "Mood pills", "Transit-aware"]}
        />
        <Card
          title="Rituals"
          accent="#5CC9C0"
          glyph="✦"
          body="Three small daily anchors — Morning Intention, Affirmation, Evening Reflection. Complete them to build a streak. Premium unlocks chart-tuned ritual prompts."
          tags={["Streak", "Three a day", "Optional"]}
        />
      </div>
    </SectionShell>
  );
}

function Card({
  title,
  accent,
  glyph,
  body,
  tags,
}: {
  title: string;
  accent: string;
  glyph: string;
  body: string;
  tags: string[];
}) {
  return (
    <div className="glass relative overflow-hidden rounded-2xl p-6">
      <div
        className="grid h-12 w-12 place-items-center rounded-xl text-2xl"
        style={{ background: `${accent}22`, color: accent }}
      >
        {glyph}
      </div>
      <h3 className="mt-4 font-display text-xl font-extrabold">{title}</h3>
      <p className="mt-2 text-sm leading-relaxed text-cosmic-muted">{body}</p>
      <div className="mt-4 flex flex-wrap gap-2">
        {tags.map((t) => (
          <span
            key={t}
            className="rounded-full border border-white/10 bg-white/5 px-2 py-1 text-[10px] font-semibold text-cosmic-muted"
          >
            {t}
          </span>
        ))}
      </div>
    </div>
  );
}
