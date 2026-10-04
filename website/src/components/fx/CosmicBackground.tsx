"use client";

import { useEffect, useRef } from "react";

/// Full-page living sky on a single <canvas>: three depth layers of
/// twinkling stars that drift with scroll and lean toward the cursor
/// (parallax), occasional shooting stars, and constellation lines that
/// light up between stars near the pointer. Fixed behind all content.
/// Falls back to a static field when the user prefers reduced motion.
export function CosmicBackground() {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    let w = 0;
    let h = 0;

    type Star = { x: number; y: number; r: number; depth: number; phase: number; speed: number; gold: boolean };
    type Meteor = { x: number; y: number; vx: number; vy: number; life: number };
    let stars: Star[] = [];
    const meteors: Meteor[] = [];

    const mouse = { x: -9999, y: -9999, tx: 0, ty: 0, px: 0, py: 0 };

    const resize = () => {
      w = window.innerWidth;
      h = window.innerHeight;
      canvas.width = w * dpr;
      canvas.height = h * dpr;
      canvas.style.width = `${w}px`;
      canvas.style.height = `${h}px`;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      const count = Math.round(Math.min(320, (w * h) / 5000));
      stars = Array.from({ length: count }, () => {
        const depth = Math.random() < 0.6 ? 0.3 : Math.random() < 0.75 ? 0.6 : 1;
        return {
          x: Math.random() * w,
          y: Math.random() * h,
          r: 0.7 + Math.random() * 1.5 * depth,
          depth,
          phase: Math.random() * Math.PI * 2,
          speed: 0.6 + Math.random() * 1.6,
          gold: Math.random() < 0.18,
        };
      });
    };

    const onMove = (e: PointerEvent) => {
      mouse.x = e.clientX;
      mouse.y = e.clientY;
      mouse.tx = (e.clientX / w - 0.5) * 2;
      mouse.ty = (e.clientY / h - 0.5) * 2;
    };
    const onLeave = () => {
      mouse.x = mouse.y = -9999;
    };

    resize();
    window.addEventListener("resize", resize);
    window.addEventListener("pointermove", onMove, { passive: true });
    document.addEventListener("pointerleave", onLeave);

    let raf = 0;
    let last = performance.now();

    const draw = (now: number) => {
      const dt = Math.min(48, now - last) / 1000;
      last = now;
      const t = now / 1000;
      const scroll = window.scrollY;

      // Ease the parallax lean toward the pointer.
      mouse.px += (mouse.tx - mouse.px) * 0.04;
      mouse.py += (mouse.ty - mouse.py) * 0.04;

      ctx.clearRect(0, 0, w, h);

      const positions: { x: number; y: number }[] = [];
      for (const s of stars) {
        const ox = mouse.px * 18 * s.depth;
        const oy = mouse.py * 18 * s.depth - scroll * 0.08 * s.depth;
        const x = (((s.x + ox) % w) + w) % w;
        const y = (((s.y + oy) % h) + h) % h;
        const tw = reduce ? 0.7 : 0.45 + 0.55 * (0.5 + 0.5 * Math.sin(t * s.speed + s.phase));
        ctx.globalAlpha = Math.min(1, tw * (0.55 + 0.6 * s.depth));
        ctx.fillStyle = s.gold ? "#E9D49A" : "#E6EAF2";
        ctx.beginPath();
        ctx.arc(x, y, s.r, 0, Math.PI * 2);
        ctx.fill();
        if (s.depth >= 0.6 && s.r > 1.2) {
          // Soft radial glow on the brightest near stars.
          const g = ctx.createRadialGradient(x, y, 0, x, y, s.r * 5);
          g.addColorStop(0, s.gold ? "rgba(233,212,154,0.35)" : "rgba(230,234,242,0.28)");
          g.addColorStop(1, "rgba(0,0,0,0)");
          ctx.globalAlpha = tw;
          ctx.fillStyle = g;
          ctx.beginPath();
          ctx.arc(x, y, s.r * 5, 0, Math.PI * 2);
          ctx.fill();
        }
        positions.push({ x, y });
      }

      // Constellation lines between stars close to the cursor.
      if (!reduce && mouse.x > -1000) {
        const near: { x: number; y: number; d: number }[] = [];
        for (const p of positions) {
          const d = Math.hypot(p.x - mouse.x, p.y - mouse.y);
          if (d < 170) near.push({ ...p, d });
        }
        ctx.lineWidth = 0.7;
        for (let i = 0; i < near.length; i++) {
          for (let j = i + 1; j < near.length; j++) {
            const a = near[i];
            const b = near[j];
            const dd = Math.hypot(a.x - b.x, a.y - b.y);
            if (dd > 110) continue;
            ctx.globalAlpha = (1 - dd / 110) * (1 - Math.max(a.d, b.d) / 170) * 0.55;
            ctx.strokeStyle = "#D4B16A";
            ctx.beginPath();
            ctx.moveTo(a.x, a.y);
            ctx.lineTo(b.x, b.y);
            ctx.stroke();
          }
        }
      }

      // Shooting stars.
      if (!reduce) {
        if (Math.random() < dt * 0.35 && meteors.length < 2) {
          const fromLeft = Math.random() < 0.5;
          meteors.push({
            x: fromLeft ? Math.random() * w * 0.5 : w * 0.5 + Math.random() * w * 0.5,
            y: Math.random() * h * 0.4,
            vx: (fromLeft ? 1 : -1) * (500 + Math.random() * 300),
            vy: 220 + Math.random() * 160,
            life: 1,
          });
        }
        for (let i = meteors.length - 1; i >= 0; i--) {
          const m = meteors[i];
          m.x += m.vx * dt;
          m.y += m.vy * dt;
          m.life -= dt * 0.9;
          if (m.life <= 0 || m.y > h + 50) {
            meteors.splice(i, 1);
            continue;
          }
          const len = 0.12;
          const grad = ctx.createLinearGradient(m.x, m.y, m.x - m.vx * len, m.y - m.vy * len);
          grad.addColorStop(0, `rgba(255,233,184,${m.life})`);
          grad.addColorStop(1, "rgba(255,233,184,0)");
          ctx.globalAlpha = 1;
          ctx.strokeStyle = grad;
          ctx.lineWidth = 1.6;
          ctx.beginPath();
          ctx.moveTo(m.x, m.y);
          ctx.lineTo(m.x - m.vx * len, m.y - m.vy * len);
          ctx.stroke();
        }
      }

      ctx.globalAlpha = 1;
      if (!reduce) raf = requestAnimationFrame(draw);
    };

    raf = requestAnimationFrame(draw);

    // Pause when the tab is hidden.
    const onVis = () => {
      if (document.hidden) cancelAnimationFrame(raf);
      else if (!reduce) {
        last = performance.now();
        raf = requestAnimationFrame(draw);
      }
    };
    document.addEventListener("visibilitychange", onVis);

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("resize", resize);
      window.removeEventListener("pointermove", onMove);
      document.removeEventListener("pointerleave", onLeave);
      document.removeEventListener("visibilitychange", onVis);
    };
  }, []);

  return (
    <>
      {/* Drifting nebula glows under the stars */}
      <div aria-hidden className="pointer-events-none fixed inset-0 -z-20 overflow-hidden">
        <div className="nebula nebula-a" />
        <div className="nebula nebula-b" />
        <div className="nebula nebula-c" />
      </div>
      <canvas ref={ref} aria-hidden className="pointer-events-none fixed inset-0 -z-10" />
    </>
  );
}
