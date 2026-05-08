"use client";

import { SectionShell } from "./SectionShell";

export function Compatibility() {
  return (
    <SectionShell
      eyebrow="Compatibility"
      title={
        <>
          See how you actually <span className="text-gold-gradient">click</span>.
        </>
      }
      blurb="Synastry between two charts — emotional, communication, and chemistry dimensions, with a written summary of your conflict patterns and the advice you both need to hear. Save partners, friends, family, anyone."
    >
      <div className="grid items-center gap-10 md:grid-cols-2">
        <div className="rounded-3xl border border-white/10 bg-white/5 p-8 text-center shadow-card">
          <div className="text-xs uppercase tracking-wider text-cosmic-dim">
            You & Sam
          </div>
          <div className="mt-2 font-display text-7xl font-black text-gold-gradient">
            87
          </div>
          <div className="text-sm font-semibold text-gold">/ 100</div>
          <div className="mt-4 text-cosmic-muted italic">
            "A magnetic alignment"
          </div>
          <div className="mt-6 grid grid-cols-3 gap-2">
            <Dim label="Emotional" v={92} color="#E14B8A" />
            <Dim label="Communication" v={84} color="#7B61FF" />
            <Dim label="Chemistry" v={89} color="#F4C542" />
          </div>
        </div>
        <div className="space-y-4 text-cosmic-muted">
          <BulletItem title="Synastry done right">
            Cross-aspect grids between every planet of both charts, weighted
            by orb strength.
          </BulletItem>
          <BulletItem title="Plain-language report">
            Three concrete sections — Summary, Conflict Patterns, and Advice
            — written for two humans, not academics.
          </BulletItem>
          <BulletItem title="Save & revisit">
            Build a private roster of people you care about. Tap any one to
            re-read the report or share it.
          </BulletItem>
        </div>
      </div>
    </SectionShell>
  );
}

function Dim({
  label,
  v,
  color,
}: {
  label: string;
  v: number;
  color: string;
}) {
  return (
    <div className="rounded-xl border border-white/10 bg-cosmic-bg/60 p-3">
      <div className="text-[9px] uppercase tracking-wider text-cosmic-dim">
        {label}
      </div>
      <div className="font-display text-2xl font-extrabold" style={{ color }}>
        {v}
      </div>
    </div>
  );
}

function BulletItem({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div className="flex gap-3">
      <span className="mt-1.5 grid h-5 w-5 flex-shrink-0 place-items-center rounded-full bg-gold/15 text-[10px] font-black text-gold">
        ✦
      </span>
      <div>
        <div className="font-display font-bold text-cosmic-text">{title}</div>
        <div className="text-sm">{children}</div>
      </div>
    </div>
  );
}
