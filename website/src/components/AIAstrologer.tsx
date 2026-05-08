"use client";

import Image from "next/image";
import { SectionShell } from "./SectionShell";

const conversation = [
  {
    role: "user",
    text: "Why have I felt restless this whole week?",
  },
  {
    role: "ai",
    text:
      "Mars is squaring your natal Moon at 17° Cancer — emotional friction asking for movement. With Mercury retrograde in your 3rd, you're rehashing recent words. Try writing the unsaid sentence down before you sleep tonight.",
  },
  {
    role: "user",
    text: "Should I have that hard conversation with Sam tomorrow?",
  },
  {
    role: "ai",
    text:
      "Tomorrow's Venus enters your 7th and trines Saturn — a rare green light for honest, anchored talk. Wait until after 2pm local; before that the Moon is void.",
  },
];

export function AIAstrologer() {
  return (
    <section id="ai" className="relative">
      <SectionShell
        eyebrow="AI Astrologer"
        title={
          <>
            A real astrologer in your pocket,
            <br />
            who <span className="text-gold-gradient">remembers</span> your
            chart.
          </>
        }
        blurb="Lively's AI knows your natal placements, current transits, and your past conversations. Ask anything — career, love, transit timing, dream interpretation. Answers come in your language: English or Türkçe today, more on the way."
      >
        <div className="grid items-center gap-10 md:grid-cols-2">
          <div className="rounded-3xl border border-white/10 bg-white/5 p-6 shadow-card">
            <div className="flex items-center gap-3 border-b border-white/10 pb-4">
              <Image
                src="/lively_logo.png"
                alt="Lively"
                width={36}
                height={36}
                className="h-9 w-9 drop-shadow-[0_0_10px_rgba(212,177,106,0.3)]"
              />
              <div>
                <div className="font-display text-sm font-bold">
                  Astrologer
                </div>
                <div className="text-[11px] text-cosmic-dim">
                  Powered by your chart
                </div>
              </div>
            </div>
            <div className="mt-4 space-y-3">
              {conversation.map((m, i) => (
                <div
                  key={i}
                  className={`flex ${
                    m.role === "user" ? "justify-end" : "justify-start"
                  }`}
                >
                  <div
                    className={`max-w-[85%] rounded-2xl px-4 py-3 text-sm leading-relaxed ${
                      m.role === "user"
                        ? "bg-gold-gradient text-[#1a1f2e]"
                        : "bg-white/5 text-cosmic-text"
                    }`}
                  >
                    {m.text}
                  </div>
                </div>
              ))}
            </div>
            <div className="mt-4 flex items-center gap-2 rounded-full border border-white/10 bg-cosmic-bg/60 px-4 py-2 text-sm text-cosmic-dim">
              <span className="text-gold">✶</span> Ask your astrologer…
            </div>
          </div>

          <div className="space-y-5">
            <Stat
              label="Free tier"
              value="Daily limit"
              detail="A handful of free messages a day; Premium unlocks unlimited."
            />
            <Stat
              label="Context window"
              value="Your chart + history"
              detail="Every reply is grounded in YOUR planets and the conversation so far."
            />
            <Stat
              label="Languages"
              value="EN · TR"
              detail="Asks and answers in the language you set in the app."
            />
            <Stat
              label="Privacy"
              value="Your data, encrypted"
              detail="Birth data is encrypted at rest. We never sell your information."
            />
          </div>
        </div>
      </SectionShell>
    </section>
  );
}

function Stat({
  label,
  value,
  detail,
}: {
  label: string;
  value: string;
  detail: string;
}) {
  return (
    <div className="flex gap-4 rounded-2xl border border-white/10 bg-white/5 p-5">
      <div className="grid h-12 w-12 flex-shrink-0 place-items-center rounded-xl bg-gold/15 font-display text-lg font-black text-gold">
        ✦
      </div>
      <div>
        <div className="text-[11px] uppercase tracking-wider text-cosmic-dim">
          {label}
        </div>
        <div className="font-display text-lg font-bold">{value}</div>
        <div className="mt-1 text-sm text-cosmic-muted">{detail}</div>
      </div>
    </div>
  );
}
