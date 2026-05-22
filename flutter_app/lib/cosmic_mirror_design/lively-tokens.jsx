// Lively — design tokens + design-system display cards
// Palette is derived from the brief: bronze-gold #D4B16A accent,
// dark cosmic + light iOS twins, warm modern premium tone.

const LIVELY_PALETTE = {
  dark: {
    name: 'Dark · Cosmic',
    bg: '#08080F',
    bgDeep: '#050509',
    surface: '#13131C',
    surfaceHi: '#1B1B27',
    surfaceGlass: 'rgba(255,255,255,0.04)',
    line: 'rgba(255,255,255,0.08)',
    glassBorder: 'rgba(212,177,106,0.22)',
    primary: '#D4B16A',
    primaryHi: '#E8C988',
    primaryDim: '#9C8049',
    onPrimary: '#1A1408',
    text: '#F2EBD9',
    textMuted: '#A09989',
    textDim: '#6A6358',
    success: '#7FB686',
    warning: '#E0A86E',
    error: '#D87575',
    gradient: 'radial-gradient(ellipse 120% 80% at 50% -10%, #1F2547 0%, #11132A 35%, #08080F 70%)',
  },
  light: {
    name: 'Light · iOS',
    bg: '#FBF7EE',
    bgDeep: '#F4EFE2',
    surface: '#FFFFFF',
    surfaceHi: '#FFFFFF',
    surfaceGlass: 'rgba(255,255,255,0.7)',
    line: 'rgba(26,22,16,0.08)',
    glassBorder: 'rgba(168,133,70,0.25)',
    primary: '#A88546',
    primaryHi: '#C09957',
    primaryDim: '#7A6233',
    onPrimary: '#FFFBF1',
    text: '#1A1610',
    textMuted: '#6B6259',
    textDim: '#A09989',
    success: '#5C8E66',
    warning: '#B57F3C',
    error: '#B85555',
    gradient: 'radial-gradient(ellipse 120% 80% at 50% -10%, #F0E5CC 0%, #F8F0DD 40%, #FBF7EE 70%)',
  },
};

// Type ramp — Instrument Serif display + Geist UI.
const LIVELY_TYPE = {
  display: '"Instrument Serif", "Cormorant Garamond", Georgia, serif',
  ui: '"Geist", "Söhne", -apple-system, BlinkMacSystemFont, system-ui, sans-serif',
  mono: '"Geist Mono", ui-monospace, "SF Mono", Menlo, monospace',
  scale: {
    d1: { size: 56, line: 60, weight: 400, family: 'display', tracking: '-0.02em' },
    d2: { size: 42, line: 46, weight: 400, family: 'display', tracking: '-0.015em' },
    d3: { size: 32, line: 36, weight: 400, family: 'display', tracking: '-0.01em' },
    h1: { size: 22, line: 28, weight: 500, family: 'ui', tracking: '-0.01em' },
    h2: { size: 17, line: 22, weight: 500, family: 'ui', tracking: '0' },
    body: { size: 15, line: 22, weight: 400, family: 'ui', tracking: '0' },
    small: { size: 13, line: 18, weight: 400, family: 'ui', tracking: '0' },
    caption: { size: 11, line: 14, weight: 500, family: 'ui', tracking: '0.06em' },
  },
};

// Spacing — 4-base, named in tokens (xs..3xl).
const LIVELY_SPACE = { xs: 4, sm: 8, md: 12, lg: 16, xl: 24, '2xl': 32, '3xl': 48, '4xl': 64 };
const LIVELY_RADIUS = { sm: 8, md: 12, lg: 16, xl: 20, '2xl': 28, full: 9999 };

// ─────────────────────────────────────────────────────────────
// Palette display card — both themes side by side as swatches.
// ─────────────────────────────────────────────────────────────
function PaletteCard({ width = 720, height = 580 }) {
  const swatches = [
    { key: 'bg', label: 'background' },
    { key: 'surface', label: 'surface' },
    { key: 'surfaceHi', label: 'surface · hi' },
    { key: 'primary', label: 'primary · gold' },
    { key: 'primaryHi', label: 'primary · hi' },
    { key: 'text', label: 'text' },
    { key: 'textMuted', label: 'text · muted' },
    { key: 'glassBorder', label: 'glass border' },
    { key: 'success', label: 'success' },
    { key: 'warning', label: 'warning' },
    { key: 'error', label: 'error' },
  ];

  const Col = ({ p, label }) => (
    <div style={{
      flex: 1, padding: 24, background: p.bg, color: p.text,
      fontFamily: LIVELY_TYPE.ui, display: 'flex', flexDirection: 'column', gap: 12,
    }}>
      <div style={{ fontFamily: LIVELY_TYPE.display, fontSize: 24, fontStyle: 'italic', color: p.primary, marginBottom: 4 }}>
        {label}
      </div>
      <div style={{ fontSize: 11, letterSpacing: '0.08em', textTransform: 'uppercase', color: p.textMuted, marginBottom: 8 }}>
        AppPalette tokens
      </div>
      {swatches.map(s => (
        <div key={s.key} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{
            width: 36, height: 36, borderRadius: 10, background: p[s.key],
            border: `1px solid ${p.line}`, flexShrink: 0,
          }} />
          <div style={{ display: 'flex', flexDirection: 'column', minWidth: 0 }}>
            <div style={{ fontSize: 13, fontWeight: 500 }}>{s.label}</div>
            <div style={{ fontSize: 11, fontFamily: LIVELY_TYPE.mono, color: p.textMuted }}>
              {p[s.key]}
            </div>
          </div>
        </div>
      ))}
    </div>
  );

  return (
    <div style={{ width, height, display: 'flex', borderRadius: 16, overflow: 'hidden', border: '1px solid rgba(0,0,0,0.06)' }}>
      <Col p={LIVELY_PALETTE.dark} label="Dark · Cosmic" />
      <Col p={LIVELY_PALETTE.light} label="Light · iOS" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Type ramp display
// ─────────────────────────────────────────────────────────────
function TypeRampCard({ width = 720, height = 580 }) {
  const p = LIVELY_PALETTE.dark;
  const samples = [
    { key: 'd1', text: 'Find your alignment' },
    { key: 'd2', text: 'Your chart, revealed' },
    { key: 'd3', text: 'Mercury enters retrograde' },
    { key: 'h1', text: 'Today\u2019s reading' },
    { key: 'h2', text: 'Section heading' },
    { key: 'body', text: 'Your moon is rising tonight — a quiet moment for reflection.' },
    { key: 'small', text: 'Small support copy under a field.' },
    { key: 'caption', text: 'SECTION LABEL · 11PX' },
  ];
  return (
    <div style={{
      width, height, background: p.bg, color: p.text, padding: 32,
      fontFamily: LIVELY_TYPE.ui, borderRadius: 16, overflow: 'hidden',
      display: 'flex', flexDirection: 'column', gap: 18,
    }}>
      <div>
        <div style={{ fontSize: 11, letterSpacing: '0.08em', textTransform: 'uppercase', color: p.textMuted }}>
          Typography
        </div>
        <div style={{ fontFamily: LIVELY_TYPE.display, fontSize: 28, fontStyle: 'italic', color: p.primary, marginTop: 4 }}>
          Instrument Serif × Geist
        </div>
      </div>
      <div style={{ height: 1, background: p.line }} />
      {samples.map(s => {
        const t = LIVELY_TYPE.scale[s.key];
        return (
          <div key={s.key} style={{ display: 'flex', alignItems: 'baseline', gap: 18 }}>
            <div style={{
              width: 60, fontSize: 10, color: p.textDim, fontFamily: LIVELY_TYPE.mono,
              letterSpacing: '0.04em', textTransform: 'uppercase', flexShrink: 0,
            }}>
              {s.key} · {t.size}
            </div>
            <div style={{
              fontFamily: t.family === 'display' ? LIVELY_TYPE.display : LIVELY_TYPE.ui,
              fontSize: t.size, lineHeight: `${t.line}px`, fontWeight: t.weight,
              letterSpacing: t.tracking,
              fontStyle: t.family === 'display' ? 'italic' : 'normal',
              color: p.text, flex: 1, minWidth: 0,
              textOverflow: 'ellipsis', overflow: 'hidden', whiteSpace: 'nowrap',
            }}>
              {s.text}
            </div>
          </div>
        );
      })}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Spacing + Radius card
// ─────────────────────────────────────────────────────────────
function TokensCard({ width = 720, height = 320 }) {
  const p = LIVELY_PALETTE.dark;
  return (
    <div style={{
      width, height, background: p.surface, color: p.text, padding: 32,
      fontFamily: LIVELY_TYPE.ui, borderRadius: 16,
      display: 'flex', gap: 40,
    }}>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 11, letterSpacing: '0.08em', textTransform: 'uppercase', color: p.textMuted, marginBottom: 12 }}>
          Spacing · 4px base
        </div>
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 10, height: 80 }}>
          {Object.entries(LIVELY_SPACE).map(([k, v]) => (
            <div key={k} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
              <div style={{ width: v, height: v, background: p.primary, borderRadius: 2 }} />
              <div style={{ fontSize: 10, color: p.textDim, fontFamily: LIVELY_TYPE.mono }}>{k}</div>
              <div style={{ fontSize: 10, color: p.textDim, fontFamily: LIVELY_TYPE.mono }}>{v}</div>
            </div>
          ))}
        </div>
      </div>
      <div style={{ width: 1, background: p.line }} />
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 11, letterSpacing: '0.08em', textTransform: 'uppercase', color: p.textMuted, marginBottom: 12 }}>
          Radius
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, height: 80 }}>
          {['sm', 'md', 'lg', 'xl', '2xl'].map(k => (
            <div key={k} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
              <div style={{
                width: 56, height: 56, background: p.surfaceHi,
                border: `1px solid ${p.glassBorder}`, borderRadius: LIVELY_RADIUS[k],
              }} />
              <div style={{ fontSize: 10, color: p.textDim, fontFamily: LIVELY_TYPE.mono }}>{k}</div>
              <div style={{ fontSize: 10, color: p.textDim, fontFamily: LIVELY_TYPE.mono }}>{LIVELY_RADIUS[k]}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { LIVELY_PALETTE, LIVELY_TYPE, LIVELY_SPACE, LIVELY_RADIUS, PaletteCard, TypeRampCard, TokensCard });
