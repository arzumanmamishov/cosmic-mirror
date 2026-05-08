"use client";

import { SectionShell } from "./SectionShell";

export function ChartShowcase() {
  return (
    <section id="charts" className="relative">
      <SectionShell
        eyebrow="Western Birth Chart"
        title={
          <>
            Your sky at the
            <br />
            <span className="text-gold-gradient">moment</span> you arrived.
          </>
        }
        blurb="Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto, Chiron, the lunar nodes — placed in their houses, with every aspect drawn. Time-zone-correct down to historical DST, decree time, and wartime offsets."
      >
        <div className="grid items-center gap-10 md:grid-cols-2">
          <BulletList
            items={[
              "Whole-sign and Placidus house systems",
              "All major + minor aspects with orbs",
              "Element + modality balance breakdown",
              "Lunar phase + day/night hemispheres",
              "Historical timezone resolution via tzf + tzdata — Soviet decree time, DST, wartime",
            ]}
          />
          <NatalWheelArt />
        </div>
      </SectionShell>
    </section>
  );
}

function BulletList({ items }: { items: string[] }) {
  return (
    <ul className="space-y-3">
      {items.map((it) => (
        <li key={it} className="flex items-start gap-3">
          <span className="mt-1.5 grid h-5 w-5 flex-shrink-0 place-items-center rounded-full bg-gold/15 text-[10px] font-black text-gold">
            ✓
          </span>
          <span className="text-cosmic-muted">{it}</span>
        </li>
      ))}
    </ul>
  );
}

function NatalWheelArt() {
  // Larger decorative natal-chart artwork built from SVG primitives.
  const sectors = Array.from({ length: 12 }, (_, i) => i);
  return (
    <div className="relative mx-auto aspect-square w-full max-w-md">
      <div className="absolute inset-0 -z-10 rounded-full bg-gold/15 blur-3xl" />
      <svg viewBox="0 0 400 400" className="h-full w-full">
        <defs>
          <radialGradient id="bg" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor="#3a4055" stopOpacity="0.5" />
            <stop offset="100%" stopColor="#1a1f2e" stopOpacity="0" />
          </radialGradient>
        </defs>
        <circle cx="200" cy="200" r="180" fill="url(#bg)" />
        {/* Outer ring */}
        <circle
          cx="200"
          cy="200"
          r="180"
          fill="none"
          stroke="#D4B16A"
          strokeOpacity="0.7"
          strokeWidth="1.5"
        />
        <circle
          cx="200"
          cy="200"
          r="140"
          fill="none"
          stroke="#D4B16A"
          strokeOpacity="0.4"
          strokeWidth="1"
        />
        <circle
          cx="200"
          cy="200"
          r="80"
          fill="none"
          stroke="#D4B16A"
          strokeOpacity="0.3"
          strokeWidth="1"
        />
        {sectors.map((i) => {
          const a = (i * 30 * Math.PI) / 180;
          const x1 = 200 + Math.cos(a) * 140;
          const y1 = 200 + Math.sin(a) * 140;
          const x2 = 200 + Math.cos(a) * 180;
          const y2 = 200 + Math.sin(a) * 180;
          return (
            <line
              key={`s${i}`}
              x1={x1}
              y1={y1}
              x2={x2}
              y2={y2}
              stroke="#D4B16A"
              strokeOpacity="0.55"
              strokeWidth="1"
            />
          );
        })}
        {sectors.map((i) => {
          const a = ((i * 30 + 15) * Math.PI) / 180;
          const x = 200 + Math.cos(a) * 160;
          const y = 200 + Math.sin(a) * 160;
          return (
            <text
              key={`g${i}`}
              x={x}
              y={y + 5}
              textAnchor="middle"
              fontSize="14"
              fill="#D4B16A"
              fontFamily="serif"
            >
              {ZODIAC_GLYPHS[i]}
            </text>
          );
        })}
        {/* Aspect lines */}
        <g strokeWidth="1.2">
          <line x1="280" y1="80" x2="120" y2="320" stroke="#7B61FF" strokeOpacity="0.7" />
          <line x1="120" y1="80" x2="320" y2="280" stroke="#5CC9C0" strokeOpacity="0.7" />
          <line x1="60" y1="200" x2="340" y2="200" stroke="#E14B8A" strokeOpacity="0.7" />
          <line x1="200" y1="60" x2="200" y2="340" stroke="#F4C542" strokeOpacity="0.55" />
        </g>
        {/* Planet dots */}
        {PLANET_POSITIONS.map((p, i) => (
          <g key={i}>
            <circle
              cx={200 + Math.cos(p.angle) * 110}
              cy={200 + Math.sin(p.angle) * 110}
              r="6"
              fill={p.color}
            />
            <text
              x={200 + Math.cos(p.angle) * 110}
              y={200 + Math.sin(p.angle) * 110 + 4}
              textAnchor="middle"
              fontSize="9"
              fill="#1a1f2e"
              fontWeight="700"
            >
              {p.glyph}
            </text>
          </g>
        ))}
        <text
          x="200"
          y="208"
          textAnchor="middle"
          fontSize="36"
          fill="#D4B16A"
          fontFamily="serif"
        >
          ☉
        </text>
      </svg>
    </div>
  );
}

const ZODIAC_GLYPHS = [
  "♈",
  "♉",
  "♊",
  "♋",
  "♌",
  "♍",
  "♎",
  "♏",
  "♐",
  "♑",
  "♒",
  "♓",
];

const PLANET_POSITIONS = [
  { angle: -1.2, glyph: "☽", color: "#E9D49A" },
  { angle: -0.4, glyph: "☿", color: "#5CC9C0" },
  { angle: 0.6, glyph: "♀", color: "#E14B8A" },
  { angle: 1.4, glyph: "♂", color: "#F07C82" },
  { angle: 2.4, glyph: "♃", color: "#F4C542" },
  { angle: 3.4, glyph: "♄", color: "#B6BAC4" },
];
