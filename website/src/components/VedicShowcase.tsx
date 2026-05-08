"use client";

import { SectionShell } from "./SectionShell";

const tabs = [
  "Rasi (D1)",
  "Navamsa (D9)",
  "Dasamsa (D10)",
  "Dvadasamsa (D12)",
  "Vimshottari Dasha",
  "Yogas",
  "Shadbala",
  "Ashtakavarga",
];

export function VedicShowcase() {
  return (
    <section className="relative bg-gradient-to-b from-transparent via-black/20 to-transparent">
      <SectionShell
        eyebrow="Vedic / Jyotish"
        title={
          <>
            The full <span className="text-gold-gradient">Indian</span>{" "}
            tradition,
            <br />
            in your pocket.
          </>
        }
        blurb="Sidereal calculations against your chosen ayanamsa (Lahiri, Raman, Krishnamurti, Fagan-Bradley). Sixteen vargas, dasha periods to three levels, classical yogas, six-fold strength, and bindu tables — everything a serious Jyotish reader expects."
      >
        <div className="grid items-stretch gap-10 md:grid-cols-5">
          <div className="md:col-span-2">
            <div className="rounded-3xl border border-white/10 bg-white/5 p-6">
              <div className="text-xs font-bold uppercase tracking-wider text-gold">
                Ayanamsa
              </div>
              <div className="mt-1 text-2xl font-extrabold">Lahiri · Sidereal</div>
              <div className="mt-4 grid grid-cols-3 gap-3 text-center">
                {[
                  ["Lagna", "Sim", "♌"],
                  ["Chandra", "Min", "♓"],
                  ["Surya", "Mes", "♈"],
                ].map(([label, sign, glyph]) => (
                  <div
                    key={label}
                    className="rounded-2xl border border-white/10 bg-cosmic-bg/60 px-3 py-3"
                  >
                    <div className="text-[10px] uppercase tracking-wider text-gold">
                      {label}
                    </div>
                    <div className="text-2xl text-cosmic-text">{glyph}</div>
                    <div className="text-[10px] text-cosmic-muted">{sign}</div>
                  </div>
                ))}
              </div>
              <div className="mt-6 flex flex-wrap gap-2">
                {tabs.map((t, i) => (
                  <span
                    key={t}
                    className={`rounded-full px-3 py-1 text-[11px] font-semibold ${
                      i === 0
                        ? "bg-gold-gradient text-[#1a1f2e]"
                        : "border border-white/10 text-cosmic-muted"
                    }`}
                  >
                    {t}
                  </span>
                ))}
              </div>
            </div>
          </div>
          <div className="md:col-span-3">
            <NorthIndianDiamond />
          </div>
        </div>
      </SectionShell>
    </section>
  );
}

/// Decorative North Indian diamond chart — fixed houses, with a few
/// planet glyphs scattered to suggest the layout. Not user-data driven.
function NorthIndianDiamond() {
  return (
    <div className="relative mx-auto aspect-square w-full max-w-md rounded-3xl border border-white/10 bg-white/5 p-6">
      <svg viewBox="0 0 300 300" className="h-full w-full">
        {/* Outer square */}
        <rect
          x="20"
          y="20"
          width="260"
          height="260"
          fill="none"
          stroke="#D4B16A"
          strokeOpacity="0.7"
          strokeWidth="1.5"
        />
        {/* Diagonals */}
        <line
          x1="20"
          y1="20"
          x2="280"
          y2="280"
          stroke="#D4B16A"
          strokeOpacity="0.5"
          strokeWidth="1"
        />
        <line
          x1="280"
          y1="20"
          x2="20"
          y2="280"
          stroke="#D4B16A"
          strokeOpacity="0.5"
          strokeWidth="1"
        />
        {/* Inner diamond */}
        <polygon
          points="150,20 280,150 150,280 20,150"
          fill="none"
          stroke="#D4B16A"
          strokeOpacity="0.7"
          strokeWidth="1.5"
        />
        {/* House numbers */}
        {[
          { n: 1, x: 150, y: 80 },
          { n: 2, x: 80, y: 80 },
          { n: 3, x: 80, y: 150 },
          { n: 4, x: 80, y: 220 },
          { n: 5, x: 150, y: 220 },
          { n: 6, x: 220, y: 220 },
          { n: 7, x: 220, y: 150 },
          { n: 8, x: 220, y: 80 },
          { n: 9, x: 150, y: 50 },
          { n: 10, x: 50, y: 150 },
          { n: 11, x: 150, y: 250 },
          { n: 12, x: 250, y: 150 },
        ].map(({ n, x, y }) => (
          <text
            key={n}
            x={x}
            y={y}
            textAnchor="middle"
            fontSize="11"
            fill="#D4B16A"
            fontWeight="600"
          >
            {n}
          </text>
        ))}
        {/* Planet glyphs */}
        {[
          { x: 150, y: 100, glyph: "☉", color: "#F4C542" },
          { x: 100, y: 100, glyph: "☽", color: "#E9D49A" },
          { x: 220, y: 100, glyph: "♂", color: "#F07C82" },
          { x: 220, y: 170, glyph: "♀", color: "#E14B8A" },
          { x: 150, y: 240, glyph: "♃", color: "#5CC9C0" },
          { x: 100, y: 170, glyph: "♄", color: "#B6BAC4" },
        ].map((p, i) => (
          <text
            key={i}
            x={p.x}
            y={p.y + 16}
            textAnchor="middle"
            fontSize="14"
            fill={p.color}
            fontFamily="serif"
          >
            {p.glyph}
          </text>
        ))}
      </svg>
    </div>
  );
}
