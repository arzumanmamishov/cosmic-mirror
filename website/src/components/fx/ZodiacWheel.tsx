"use client";

import { motion, useReducedMotion, useScroll, useTransform } from "framer-motion";

// Round SVG coordinates so server- and client-rendered markup match
// exactly (Math.cos can differ in the last digit between runtimes).
const r2 = (n: number) => Math.round(n * 100) / 100;

const SIGNS = ["♈", "♉", "♊", "♋", "♌", "♍", "♎", "♏", "♐", "♑", "♒", "♓"];

/// Large decorative zodiac wheel: an outer ring of sign glyphs turning
/// slowly (and a little extra as you scroll), tick marks, and planets
/// orbiting on inner rings. Purely decorative.
export function ZodiacWheel({ className = "" }: { className?: string }) {
  const reduce = useReducedMotion();
  const { scrollY } = useScroll();
  const scrollTurn = useTransform(scrollY, [0, 1200], [0, 60]);

  return (
    <div aria-hidden className={`pointer-events-none ${className}`}>
      <motion.div style={{ rotate: reduce ? 0 : scrollTurn }} className="h-full w-full">
        <motion.svg
          viewBox="0 0 600 600"
          className="h-full w-full"
          animate={reduce ? undefined : { rotate: 360 }}
          transition={{ duration: 180, ease: "linear", repeat: Infinity }}
        >
          <defs>
            <radialGradient id="zwGlow" cx="50%" cy="50%" r="50%">
              <stop offset="0%" stopColor="#D4B16A" stopOpacity="0.16" />
              <stop offset="70%" stopColor="#D4B16A" stopOpacity="0.03" />
              <stop offset="100%" stopColor="#D4B16A" stopOpacity="0" />
            </radialGradient>
          </defs>
          <circle cx="300" cy="300" r="290" fill="url(#zwGlow)" />
          <circle cx="300" cy="300" r="282" fill="none" stroke="#D4B16A" strokeOpacity="0.45" strokeWidth="1" />
          <circle cx="300" cy="300" r="232" fill="none" stroke="#D4B16A" strokeOpacity="0.3" strokeWidth="1" />
          {Array.from({ length: 72 }, (_, i) => {
            const a = (i * 5 * Math.PI) / 180;
            const long = i % 6 === 0;
            const r1 = long ? 232 : 270;
            return (
              <line
                key={i}
                x1={r2(300 + Math.cos(a) * r1)}
                y1={r2(300 + Math.sin(a) * r1)}
                x2={r2(300 + Math.cos(a) * 282)}
                y2={r2(300 + Math.sin(a) * 282)}
                stroke="#D4B16A"
                strokeOpacity={long ? 0.5 : 0.22}
                strokeWidth={long ? 1.2 : 0.8}
              />
            );
          })}
          {SIGNS.map((s, i) => {
            const a = ((i * 30 + 15) * Math.PI) / 180;
            return (
              <text
                key={s}
                x={r2(300 + Math.cos(a) * 252)}
                y={r2(300 + Math.sin(a) * 252)}
                textAnchor="middle"
                dominantBaseline="central"
                fontSize="24"
                fill="#E9D49A"
                fillOpacity="0.75"
              >
                {s}
                {"︎"}
              </text>
            );
          })}
        </motion.svg>
      </motion.div>

      {/* Orbiting planets on inner rings */}
      {[
        { r: 41, d: 26, size: 10, color: "#E9D49A", start: 0 },
        { r: 33, d: 18, size: 7, color: "#7B61FF", start: 120 },
        { r: 25, d: 12, size: 6, color: "#5CC9C0", start: 240 },
      ].map((o, i) => (
        <motion.div
          key={i}
          className="absolute left-1/2 top-1/2"
          style={{ width: `${o.r * 2}%`, height: `${o.r * 2}%`, x: "-50%", y: "-50%" }}
          initial={{ rotate: o.start }}
          animate={reduce ? undefined : { rotate: o.start + 360 }}
          transition={{ duration: o.d, ease: "linear", repeat: Infinity }}
        >
          <div className="absolute inset-0 rounded-full border border-dashed border-gold/15" />
          <span
            className="absolute left-1/2 top-0 -translate-x-1/2 -translate-y-1/2 rounded-full"
            style={{
              width: o.size,
              height: o.size,
              background: o.color,
              boxShadow: `0 0 14px 3px ${o.color}88`,
            }}
          />
        </motion.div>
      ))}
    </div>
  );
}
