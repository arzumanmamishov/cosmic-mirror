// Lively — shared screen primitives.
// All draw from window.LIVELY_PALETTE[theme]; the screens pass `t` (theme key).

// ─────────────────────────────────────────────────────────────
// Global animation CSS — one injection per page.
// ─────────────────────────────────────────────────────────────
if (typeof document !== 'undefined' && !document.getElementById('lively-anims')) {
  const s = document.createElement('style');
  s.id = 'lively-anims';
  s.textContent = `
    @keyframes lively-twinkle {
      0%, 100% { opacity: var(--tw-min, 0.18); transform: scale(1); }
      50% { opacity: var(--tw-max, 0.7); transform: scale(1.18); }
    }
    @keyframes lively-screen-in {
      from { opacity: 0; transform: translateY(14px); }
      to   { opacity: 1; transform: translateY(0); }
    }
    @keyframes lively-screen-out {
      from { opacity: 1; transform: translateY(0); }
      to   { opacity: 0; transform: translateY(-14px); }
    }
    @keyframes lively-rise {
      from { opacity: 0; transform: translateY(8px); }
      to   { opacity: 1; transform: translateY(0); }
    }
    @keyframes lively-scale-in {
      from { opacity: 0; transform: scale(0.6); }
      to   { opacity: 1; transform: scale(1); }
    }
    @keyframes lively-glow-pulse {
      0%, 100% { box-shadow: 0 0 0 3px rgba(212,177,106,0.18); }
      50%      { box-shadow: 0 0 0 6px rgba(212,177,106,0.28); }
    }
    @keyframes lively-wheel-draw {
      from { stroke-dashoffset: 1000; opacity: 0; }
      to   { stroke-dashoffset: 0; opacity: 0.6; }
    }
    @keyframes lively-bar-fill {
      from { width: 0%; }
      to   { width: var(--bar-w, 100%); }
    }
    @keyframes lively-aurora-drift {
      0%, 100% { transform: translateX(-50%) translateY(0); opacity: 0.06; }
      50%      { transform: translateX(-50%) translateY(-8px); opacity: 0.10; }
    }
    .lively-press:active { transform: scale(0.97); transition: transform .08s; }
    .lively-press { transition: transform .12s; }

    .lively-screen-enter { animation: lively-screen-in .42s cubic-bezier(.2,.7,.2,1) both; }
    .lively-screen-exit  { animation: lively-screen-out .25s cubic-bezier(.5,0,.7,.3) both; position: absolute; inset: 0; }

    .lively-twk { animation: lively-twinkle 4s ease-in-out infinite; transform-origin: center; transform-box: fill-box; }
  `;
  document.head.appendChild(s);
}

// Deterministic starfield — same seed → same layout, so artboards don't shimmer
// every re-render. Density is light (this is "premium, not kitsch").
const _starCache = {};
function _starfield(seed, count, w, h) {
  const k = `${seed}-${count}-${w}-${h}`;
  if (_starCache[k]) return _starCache[k];
  // tiny LCG
  let s = seed;
  const rnd = () => { s = (s * 1664525 + 1013904223) % 4294967296; return s / 4294967296; };
  const stars = [];
  for (let i = 0; i < count; i++) {
    const big = rnd() < 0.08;
    stars.push({
      x: rnd() * w, y: rnd() * h,
      r: big ? 1.6 + rnd() * 0.8 : 0.4 + rnd() * 0.8,
      a: big ? 0.55 + rnd() * 0.35 : 0.15 + rnd() * 0.4,
      tw: rnd() < 0.3, // tiny shimmer marker (we won't animate by default)
    });
  }
  _starCache[k] = stars;
  return stars;
}

// Background — radial cosmic gradient + sparse stars.
// Used full-bleed inside an iOS/Android screen.
function LivelyBackdrop({ theme = 'dark', seed = 7, intensity = 1, children, top = 0 }) {
  const p = LIVELY_PALETTE[theme];
  const w = 402, h = 874;
  const count = theme === 'dark' ? Math.round(80 * intensity) : Math.round(28 * intensity);
  const stars = _starfield(seed, count, w, h);
  return (
    <div style={{
      position: 'absolute', inset: 0, background: p.gradient,
      overflow: 'hidden', color: p.text,
    }}>
      {/* starfield — only on dark, light gets a faint dust */}
      <svg
        viewBox={`0 0 ${w} ${h}`}
        preserveAspectRatio="xMidYMid slice"
        style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', pointerEvents: 'none' }}
      >
        {stars.map((s, i) => (
          <circle
            key={i} cx={s.x} cy={s.y} r={s.r}
            fill={theme === 'dark' ? '#FFF6E0' : '#A88546'}
            opacity={theme === 'dark' ? s.a : s.a * 0.35}
            className={s.tw ? 'lively-twk' : undefined}
            style={s.tw ? {
              '--tw-min': theme === 'dark' ? s.a * 0.4 : s.a * 0.2,
              '--tw-max': theme === 'dark' ? Math.min(1, s.a * 1.6) : s.a * 0.6,
              animationDelay: `${(i % 7) * 0.5}s`,
              animationDuration: `${3.5 + (i % 5) * 0.6}s`,
            } : undefined}
          />
        ))}
        {/* one subtle wide aurora wash near the top */}
        {theme === 'dark' && (
          <ellipse cx={w / 2} cy={-40} rx={w * 0.7} ry={180}
            fill={p.primary} opacity={0.06}
            style={{ animation: 'lively-aurora-drift 7s ease-in-out infinite' }} />
        )}
      </svg>
      <div style={{ position: 'relative', height: '100%', paddingTop: top }}>
        {children}
      </div>
    </div>
  );
}

// Logo mark — a small rotated 8-pointed sparkle in gold + a thin ring.
function LivelyMark({ size = 28, color, ring }) {
  const c = color || LIVELY_PALETTE.dark.primary;
  const r = ring || 'rgba(212,177,106,0.4)';
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" style={{ display: 'block' }}>
      <circle cx="16" cy="16" r="14.5" fill="none" stroke={r} strokeWidth="0.6" />
      {/* 8-point sparkle */}
      <path d="M16 3 L17 14 L28 16 L17 18 L16 29 L15 18 L4 16 L15 14 Z" fill={c} />
      <circle cx="16" cy="16" r="1.6" fill={c} />
    </svg>
  );
}

function LivelyWordmark({ size = 26, color, italic = true }) {
  return (
    <span style={{
      fontFamily: LIVELY_TYPE.display, fontSize: size,
      fontStyle: italic ? 'italic' : 'normal', fontWeight: 400,
      color: color || LIVELY_PALETTE.dark.text, letterSpacing: '-0.01em',
    }}>Lively</span>
  );
}

// Pill button — primary gold. The hero CTA.
function GoldButton({ children, theme = 'dark', onClick, full = true, small = false, ghost = false }) {
  const p = LIVELY_PALETTE[theme];
  const bg = ghost ? 'transparent' : p.primary;
  const fg = ghost ? p.primary : p.onPrimary;
  const border = ghost ? `1px solid ${p.glassBorder}` : 'none';
  return (
    <button onClick={onClick} className="lively-press" style={{
      width: full ? '100%' : 'auto',
      padding: small ? '11px 18px' : '15px 22px',
      borderRadius: 999, border, background: bg, color: fg,
      fontFamily: LIVELY_TYPE.ui, fontSize: small ? 14 : 16, fontWeight: 600,
      letterSpacing: '-0.005em', cursor: 'pointer',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      boxShadow: ghost ? 'none' : `0 1px 0 ${p.primaryHi} inset, 0 8px 24px rgba(212,177,106,0.18)`,
      transition: 'transform .12s',
    }}>
      {children}
    </button>
  );
}

// Glass card — translucent surface with gold-tinted border.
function GlassCard({ children, theme = 'dark', style, padding = 18, radius = 20, onClick }) {
  const p = LIVELY_PALETTE[theme];
  return (
    <div onClick={onClick} style={{
      background: theme === 'dark' ? 'rgba(255,255,255,0.04)' : 'rgba(255,255,255,0.8)',
      backdropFilter: 'blur(20px) saturate(150%)',
      WebkitBackdropFilter: 'blur(20px) saturate(150%)',
      border: `1px solid ${p.glassBorder}`,
      borderRadius: radius, padding, color: p.text,
      cursor: onClick ? 'pointer' : 'default',
      ...style,
    }}>{children}</div>
  );
}

// Form field — fill = page background per brief.
function FormField({ label, value, placeholder, theme = 'dark', focused = false, suffix, prefix, large = false }) {
  const p = LIVELY_PALETTE[theme];
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
      {label && (
        <div style={{
          fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase',
          color: p.textMuted, fontFamily: LIVELY_TYPE.ui, fontWeight: 500,
        }}>{label}</div>
      )}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        padding: large ? '18px 18px' : '14px 16px',
        // Same color as page background — per brief.
        background: p.bg,
        border: `1px solid ${focused ? p.primary : p.line}`,
        borderRadius: 14,
        boxShadow: focused ? `0 0 0 3px ${p.primary}22` : 'none',
        transition: 'border-color .15s, box-shadow .15s',
      }}>
        {prefix && <div style={{ color: p.textMuted, fontSize: 16 }}>{prefix}</div>}
        <div style={{
          flex: 1, color: value ? p.text : p.textDim,
          fontFamily: LIVELY_TYPE.ui, fontSize: large ? 18 : 16, fontWeight: value ? 500 : 400,
          letterSpacing: '-0.01em',
        }}>
          {value || placeholder}
        </div>
        {suffix && <div style={{ color: p.textMuted, fontSize: 14 }}>{suffix}</div>}
      </div>
    </div>
  );
}

// Progress — 5 dots with a connecting hair-thin rail.
function StepProgress({ step, total = 5, theme = 'dark' }) {
  const p = LIVELY_PALETTE[theme];
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
      {Array.from({ length: total }).map((_, i) => {
        const done = i < step;
        const active = i === step;
        return (
          <div key={i} style={{
            flex: active ? '0 0 22px' : '0 0 6px',
            height: 6, borderRadius: 999,
            background: done || active ? p.primary : p.line,
            transition: 'flex-basis .25s',
          }} />
        );
      })}
    </div>
  );
}

// Chip — for focus-area selection.
function Chip({ label, icon, selected = false, theme = 'dark', onClick }) {
  const p = LIVELY_PALETTE[theme];
  return (
    <div onClick={onClick} style={{
      padding: '12px 14px',
      borderRadius: 14,
      background: selected
        ? (theme === 'dark' ? 'rgba(212,177,106,0.14)' : 'rgba(168,133,70,0.12)')
        : (theme === 'dark' ? 'rgba(255,255,255,0.03)' : '#fff'),
      border: `1px solid ${selected ? p.primary : p.line}`,
      color: selected ? p.primary : p.text,
      display: 'flex', alignItems: 'center', gap: 10,
      fontFamily: LIVELY_TYPE.ui, fontSize: 14, fontWeight: 500,
      cursor: 'pointer', transition: 'all .15s',
    }}>
      {icon && <span style={{ fontSize: 16, opacity: selected ? 1 : 0.7 }}>{icon}</span>}
      <span>{label}</span>
    </div>
  );
}

// Tiny zodiac glyph helpers (used in Welcome reveal).
const ZODIAC_GLYPHS = {
  aries: '\u2648', taurus: '\u2649', gemini: '\u264A', cancer: '\u264B',
  leo: '\u264C', virgo: '\u264D', libra: '\u264E', scorpio: '\u264F',
  sagittarius: '\u2650', capricorn: '\u2651', aquarius: '\u2652', pisces: '\u2653',
};

// Mini chart wheel — a thin gold ring with 12 ticks, used in Welcome.
function MiniWheel({ size = 220, theme = 'dark', sun = 'leo', moon = 'pisces', rising = 'scorpio' }) {
  const p = LIVELY_PALETTE[theme];
  const cx = size / 2, cy = size / 2;
  const outer = size / 2 - 4;
  const inner = outer - 22;
  const ticks = Array.from({ length: 12 });
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      <defs>
        <radialGradient id="lw-rg" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor={p.primary} stopOpacity="0.08" />
          <stop offset="80%" stopColor={p.primary} stopOpacity="0" />
        </radialGradient>
      </defs>
      <circle cx={cx} cy={cy} r={outer} fill="url(#lw-rg)" />
      <circle cx={cx} cy={cy} r={outer} fill="none" stroke={p.primary} strokeWidth="0.8" opacity="0.6" />
      <circle cx={cx} cy={cy} r={inner} fill="none" stroke={p.primary} strokeWidth="0.5" opacity="0.4" />
      {ticks.map((_, i) => {
        const a = (i / 12) * Math.PI * 2 - Math.PI / 2;
        const x1 = cx + Math.cos(a) * inner;
        const y1 = cy + Math.sin(a) * inner;
        const x2 = cx + Math.cos(a) * outer;
        const y2 = cy + Math.sin(a) * outer;
        return <line key={i} x1={x1} y1={y1} x2={x2} y2={y2} stroke={p.primary} strokeWidth="0.5" opacity="0.5" />;
      })}
      {/* the three "luminaries" — Sun, Moon, Rising — placed at conceptual angles */}
      {[
        { glyph: ZODIAC_GLYPHS[sun], label: 'Sun', a: -Math.PI / 3, r: (inner + outer) / 2 - 30 },
        { glyph: ZODIAC_GLYPHS[moon], label: 'Moon', a: Math.PI / 2.4, r: (inner + outer) / 2 - 30 },
        { glyph: ZODIAC_GLYPHS[rising], label: 'Rising', a: Math.PI - 0.3, r: (inner + outer) / 2 - 30 },
      ].map((m, i) => {
        const x = cx + Math.cos(m.a) * m.r;
        const y = cy + Math.sin(m.a) * m.r;
        return (
          <g key={i}>
            <circle cx={x} cy={y} r="14" fill={p.bg} stroke={p.primary} strokeWidth="0.6" />
            <text x={x} y={y + 5} fontSize="14" textAnchor="middle" fill={p.primary} fontFamily="system-ui">
              {m.glyph}
            </text>
          </g>
        );
      })}
      {/* center dot */}
      <circle cx={cx} cy={cy} r="2" fill={p.primary} />
    </svg>
  );
}

Object.assign(window, {
  LivelyBackdrop, LivelyMark, LivelyWordmark, GoldButton, GlassCard,
  FormField, StepProgress, Chip, MiniWheel, ZODIAC_GLYPHS,
});
