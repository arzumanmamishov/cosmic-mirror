"use client";

import { motion } from "framer-motion";

/// Stylized phone frame with a simulated app screen rendered in pure SVG.
/// Avoids shipping real screenshots while still giving the page a strong
/// visual centerpiece. Subtle floaty animation keeps it alive.
export function PhoneMock() {
  return (
    <motion.div
      animate={{ y: [0, -10, 0] }}
      transition={{ duration: 6, ease: "easeInOut", repeat: Infinity }}
      className="relative mx-auto w-[260px] md:w-[320px]"
    >
      {/* Soft halo behind the device */}
      <div className="absolute inset-0 -z-10 translate-y-6 scale-95 rounded-[3rem] bg-gold/15 blur-3xl" />
      {/* Phone frame */}
      <div className="relative aspect-[9/19] rounded-[3rem] bg-gradient-to-b from-[#2A2F3E] to-[#15192B] p-2 shadow-card ring-1 ring-white/10">
        <div className="relative h-full w-full overflow-hidden rounded-[2.5rem] bg-cosmic-bg">
          {/* Status bar */}
          <div className="flex items-center justify-between px-6 pt-3 text-[10px] text-cosmic-muted">
            <span>9:41</span>
            <span>•••••</span>
          </div>
          {/* App content */}
          <div className="px-5 pt-3">
            <div className="text-[10px] uppercase tracking-wider text-cosmic-dim">
              Today
            </div>
            <div className="mt-1 font-display text-lg font-extrabold text-gold">
              Your sky right now
            </div>

            {/* Big-three card */}
            <div className="mt-4 rounded-2xl border border-white/5 bg-white/5 p-3">
              <div className="grid grid-cols-3 gap-2 text-center">
                <BigSign label="Sun" sign="Aries" glyph="☉" />
                <BigSign label="Moon" sign="Pisces" glyph="☽" />
                <BigSign label="Rising" sign="Leo" glyph="↑" />
              </div>
            </div>

            {/* Mini chart wheel */}
            <div className="mt-4 flex items-center justify-center">
              <ChartWheelSVG />
            </div>

            {/* Today's energies pill */}
            <div className="mt-4 rounded-xl border border-gold/30 bg-gold/10 px-3 py-2 text-[11px] text-gold">
              ✨ Heart-forward day — Venus invites warmth in conversation.
            </div>

            {/* Tabs */}
            <div className="absolute inset-x-0 bottom-3 flex justify-around px-6 text-[10px]">
              {["Home", "Charts", "Chat", "Spaces"].map((t, i) => (
                <div
                  key={t}
                  className={`flex flex-col items-center gap-1 ${
                    i === 1 ? "text-gold" : "text-cosmic-dim"
                  }`}
                >
                  <span className="h-1 w-1 rounded-full bg-current" />
                  <span>{t}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </motion.div>
  );
}

function BigSign({
  label,
  sign,
  glyph,
}: {
  label: string;
  sign: string;
  glyph: string;
}) {
  return (
    <div className="rounded-xl bg-white/5 px-2 py-2">
      <div className="text-base text-gold">{glyph}</div>
      <div className="text-[8px] uppercase tracking-wider text-cosmic-dim">
        {label}
      </div>
      <div className="mt-0.5 text-[10px] font-bold text-cosmic-text">
        {sign}
      </div>
    </div>
  );
}

function ChartWheelSVG() {
  // Simple cosmetic natal-wheel — 12 sectors with the gold ring + central
  // glyph. Not astronomically accurate; just suggestive.
  const sectors = Array.from({ length: 12 }, (_, i) => i);
  return (
    <svg viewBox="0 0 200 200" className="h-44 w-44 drop-shadow-[0_0_24px_rgba(212,177,106,0.3)]">
      <defs>
        <radialGradient id="wheelG" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#3a4055" stopOpacity="0.6" />
          <stop offset="100%" stopColor="#1a1f2e" stopOpacity="0" />
        </radialGradient>
      </defs>
      <circle cx="100" cy="100" r="85" fill="url(#wheelG)" />
      <circle
        cx="100"
        cy="100"
        r="85"
        fill="none"
        stroke="#D4B16A"
        strokeOpacity="0.6"
        strokeWidth="1.2"
      />
      <circle
        cx="100"
        cy="100"
        r="62"
        fill="none"
        stroke="#D4B16A"
        strokeOpacity="0.35"
        strokeWidth="0.8"
      />
      {sectors.map((i) => {
        const a = (i * 30 * Math.PI) / 180;
        const x1 = 100 + Math.cos(a) * 62;
        const y1 = 100 + Math.sin(a) * 62;
        const x2 = 100 + Math.cos(a) * 85;
        const y2 = 100 + Math.sin(a) * 85;
        return (
          <line
            key={i}
            x1={x1}
            y1={y1}
            x2={x2}
            y2={y2}
            stroke="#D4B16A"
            strokeOpacity="0.45"
            strokeWidth="0.8"
          />
        );
      })}
      {/* Inner aspect lines (just a few, for vibe) */}
      <line
        x1="40"
        y1="100"
        x2="160"
        y2="80"
        stroke="#7B61FF"
        strokeOpacity="0.6"
        strokeWidth="1"
      />
      <line
        x1="100"
        y1="40"
        x2="60"
        y2="150"
        stroke="#5CC9C0"
        strokeOpacity="0.55"
        strokeWidth="1"
      />
      <line
        x1="160"
        y1="120"
        x2="60"
        y2="60"
        stroke="#E14B8A"
        strokeOpacity="0.55"
        strokeWidth="1"
      />
      {/* Center glyph */}
      <text
        x="100"
        y="106"
        textAnchor="middle"
        className="font-display"
        fill="#D4B16A"
        fontSize="22"
      >
        ☉
      </text>
    </svg>
  );
}
