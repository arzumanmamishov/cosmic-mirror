"use client";

import { SectionShell } from "./SectionShell";

export function HumanDesignShowcase() {
  return (
    <SectionShell
      eyebrow="Human Design"
      title={
        <>
          Type. Strategy. Authority.
          <br />
          Your <span className="text-gold-gradient">body graph</span>.
        </>
      }
      blurb="Lively renders the iconic Human Design body graph — nine centers, sixty-four gates, thirty-six channels. We compute Personality (conscious) and Design (unconscious, 88° solar arc earlier) activations from Swiss Ephemeris, derive your Type (Generator / MG / Manifestor / Projector / Reflector), Authority, Profile, Definition, Incarnation Cross, and Variables."
    >
      <div className="grid gap-10 md:grid-cols-2 md:items-center">
        <div className="space-y-4">
          <Pill title="Generator" subtitle="Strategy: respond" tone="primary" />
          <Pill title="Sacral Authority" subtitle="Trust the gut yes/no" tone="dim" />
          <Pill title="3/5 Profile" subtitle="Martyr · Heretic" tone="dim" />
          <Pill
            title="Right-Angle Cross of Planning"
            subtitle="Incarnation cross"
            tone="dim"
          />
          <Pill title="Single definition" subtitle="One connected stream" tone="dim" />
          <p className="pt-3 text-sm text-cosmic-muted">
            The body graph is hand-drawn in Flutter — gates colored gold for
            vowels of intent, channels routed by classical HD circuit theory
            (Integration, Individual, Tribal, Logic, Sensing).
          </p>
        </div>
        <BodyGraphArt />
      </div>
    </SectionShell>
  );
}

function Pill({
  title,
  subtitle,
  tone,
}: {
  title: string;
  subtitle: string;
  tone: "primary" | "dim";
}) {
  return (
    <div
      className={`flex items-center gap-4 rounded-2xl border p-4 ${
        tone === "primary"
          ? "border-gold/40 bg-gold/10"
          : "border-white/10 bg-white/5"
      }`}
    >
      <span
        className={`grid h-10 w-10 place-items-center rounded-xl text-xl ${
          tone === "primary" ? "bg-gold-gradient text-[#1a1f2e]" : "bg-white/10 text-gold"
        }`}
      >
        ✦
      </span>
      <div>
        <div className="font-display text-base font-bold text-cosmic-text">
          {title}
        </div>
        <div className="text-xs text-cosmic-muted">{subtitle}</div>
      </div>
    </div>
  );
}

/// Decorative body graph — nine centers in canonical positions, two
/// channels lit. Doesn't represent a real chart; just suggestive.
function BodyGraphArt() {
  return (
    <div className="relative mx-auto aspect-[4/7] w-full max-w-xs rounded-3xl border border-white/10 bg-white/5 p-4">
      <svg viewBox="0 0 200 350" className="h-full w-full">
        {/* Channels (drawn first so centers sit on top) */}
        <line x1="100" y1="25" x2="100" y2="80" stroke="#D4B16A" strokeWidth="3" opacity="0.85" />
        <line x1="100" y1="115" x2="100" y2="155" stroke="#D4B16A" strokeWidth="3" opacity="0.85" />
        <line x1="100" y1="195" x2="100" y2="245" stroke="#D4B16A" strokeWidth="3" opacity="0.85" />
        <line x1="100" y1="180" x2="160" y2="245" stroke="#E9D49A" strokeWidth="2.5" opacity="0.6" />
        <line x1="100" y1="180" x2="40" y2="245" stroke="#E9D49A" strokeWidth="2.5" opacity="0.6" />
        <line x1="100" y1="265" x2="100" y2="320" stroke="#D4B16A" strokeWidth="3" opacity="0.85" />

        {/* Head — triangle up */}
        <polygon points="100,5 130,40 70,40" fill="#F4C542" stroke="#D4B16A" strokeWidth="1" />
        {/* Ajna — triangle down */}
        <polygon points="70,80 130,80 100,115" fill="#5CC9C0" stroke="#D4B16A" strokeWidth="1" opacity="0.6" />
        {/* Throat — square */}
        <rect x="70" y="125" width="60" height="35" fill="#3a4055" stroke="#D4B16A" strokeWidth="1" />
        {/* G — diamond */}
        <polygon points="100,165 130,195 100,225 70,195" fill="#D4B16A" stroke="#D4B16A" strokeWidth="1" />
        {/* Heart — small triangle */}
        <polygon points="155,180 175,210 135,210" fill="#3a4055" stroke="#D4B16A" strokeWidth="1" opacity="0.6" />
        {/* Spleen — left triangle */}
        <polygon points="20,205 50,225 20,245" fill="#3a4055" stroke="#D4B16A" strokeWidth="1" opacity="0.6" />
        {/* Sacral — square */}
        <rect x="70" y="225" width="60" height="40" fill="#E14B8A" stroke="#D4B16A" strokeWidth="1" opacity="0.85" />
        {/* Solar plexus — right triangle */}
        <polygon points="180,205 150,225 180,245" fill="#3a4055" stroke="#D4B16A" strokeWidth="1" opacity="0.6" />
        {/* Root — square */}
        <rect x="70" y="290" width="60" height="40" fill="#9F7637" stroke="#D4B16A" strokeWidth="1" opacity="0.85" />
      </svg>
    </div>
  );
}
