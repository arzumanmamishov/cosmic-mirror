"use client";

import { SectionShell } from "./SectionShell";

export function Languages() {
  return (
    <SectionShell
      align="center"
      eyebrow="Speaks your language"
      title={
        <>
          English. <span className="text-gold-gradient">Türkçe.</span> More
          coming.
        </>
      }
      blurb="Every screen, every reading, every notification — fully translated. Pick your language in Settings; the AI astrologer answers in it too."
    >
      <div className="mx-auto flex max-w-xl flex-wrap items-center justify-center gap-3">
        {[
          { code: "EN", label: "English", live: true },
          { code: "TR", label: "Türkçe", live: true },
          { code: "AZ", label: "Azərbaycanca", live: false },
          { code: "RU", label: "Русский", live: false },
          { code: "ES", label: "Español", live: false },
          { code: "DE", label: "Deutsch", live: false },
        ].map((l) => (
          <span
            key={l.code}
            className={`flex items-center gap-2 rounded-full border px-4 py-2 text-sm ${
              l.live
                ? "border-gold/40 bg-gold/10 text-gold"
                : "border-white/10 bg-white/5 text-cosmic-muted"
            }`}
          >
            <span className="font-display text-xs font-black">{l.code}</span>
            <span className={l.live ? "" : "opacity-70"}>{l.label}</span>
            {!l.live && (
              <span className="text-[10px] uppercase tracking-wider text-cosmic-dim">
                soon
              </span>
            )}
          </span>
        ))}
      </div>
    </SectionShell>
  );
}
