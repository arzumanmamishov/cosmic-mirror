// Lively — first-impression screens, part 2.
// Place picker, Focus selection, and Welcome / chart reveal.

// ─────────────────────────────────────────────────────────────
// 4 · PLACE OF BIRTH
// ─────────────────────────────────────────────────────────────
function PlaceScreen({ theme = 'dark', onNext, onBack }) {
  const p = LIVELY_PALETTE[theme];
  const cities = [
    { name: 'Istanbul', sub: 'Türkiye', tz: 'GMT+3', selected: true },
    { name: 'Istanbul, NY', sub: 'United States', tz: 'GMT-5' },
    { name: 'Istanbul, MN', sub: 'United States', tz: 'GMT-6' },
  ];
  return (
    <OnboardingShell
      step={3} theme={theme} onNext={onNext} onBack={onBack}
      kicker="Step 4 · Birthplace"
      title={<>Where in the<br/>world?</>}
      subtitle="The horizon — your Ascendant — depends on the longitude and latitude of where you were born."
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
        <FormField
          theme={theme}
          value="Istanbul"
          prefix={
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
              <path d="M8 1 C5 1 3 3 3 6 c0 4 5 9 5 9 s5 -5 5 -9 c0 -3 -2 -5 -5 -5z"
                stroke={p.textMuted} strokeWidth="1.3" fill="none" />
              <circle cx="8" cy="6" r="1.8" fill={p.textMuted} />
            </svg>
          }
          focused
        />

        {/* result list */}
        <div style={{
          background: theme === 'dark' ? 'rgba(255,255,255,0.03)' : '#fff',
          border: `1px solid ${p.line}`, borderRadius: 16, overflow: 'hidden',
        }}>
          {cities.map((c, i) => (
            <div key={i} style={{
              padding: '14px 16px',
              borderTop: i ? `1px solid ${p.line}` : 'none',
              display: 'flex', alignItems: 'center', gap: 14,
              background: c.selected
                ? (theme === 'dark' ? 'rgba(212,177,106,0.08)' : 'rgba(168,133,70,0.08)')
                : 'transparent',
            }}>
              <div style={{
                width: 32, height: 32, borderRadius: 10,
                background: c.selected ? p.primary : (theme === 'dark' ? 'rgba(255,255,255,0.04)' : p.bgDeep),
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
                  <path d="M8 1 C5 1 3 3 3 6 c0 4 5 9 5 9 s5 -5 5 -9 c0 -3 -2 -5 -5 -5z"
                    stroke={c.selected ? p.onPrimary : p.text} strokeWidth="1.3" fill="none" />
                  <circle cx="8" cy="6" r="1.6" fill={c.selected ? p.onPrimary : p.text} />
                </svg>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 15, fontWeight: 500, color: p.text }}>{c.name}</div>
                <div style={{ fontSize: 12, color: p.textMuted, marginTop: 2 }}>{c.sub}</div>
              </div>
              <div style={{
                fontSize: 10, fontFamily: LIVELY_TYPE.mono, letterSpacing: '0.06em',
                color: c.selected ? p.primary : p.textMuted,
              }}>{c.tz}</div>
            </div>
          ))}
        </div>

        {/* tiny "map" — abstract latitude tick */}
        <div style={{
          marginTop: 6, padding: 16, borderRadius: 16,
          background: theme === 'dark' ? 'rgba(255,255,255,0.025)' : '#fff',
          border: `1px solid ${p.line}`,
        }}>
          <div style={{
            fontSize: 10, letterSpacing: '0.12em', textTransform: 'uppercase',
            color: p.textMuted, marginBottom: 10,
          }}>Coordinates</div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ fontFamily: LIVELY_TYPE.mono, fontSize: 14, color: p.text }}>41.0082° N</div>
              <div style={{ fontFamily: LIVELY_TYPE.mono, fontSize: 14, color: p.text, marginTop: 4 }}>28.9784° E</div>
            </div>
            {/* mini horizon arc */}
            <svg width="120" height="44" viewBox="0 0 120 44">
              <path d="M2 36 Q60 -4 118 36" stroke={p.primary} strokeWidth="1" fill="none" opacity="0.5" />
              <line x1="2" y1="36" x2="118" y2="36" stroke={p.textMuted} strokeWidth="0.5" strokeDasharray="2 3" opacity="0.5" />
              <circle cx="78" cy="14" r="3" fill={p.primary} />
              <line x1="78" y1="14" x2="78" y2="36" stroke={p.primary} strokeWidth="0.6" opacity="0.5" />
            </svg>
          </div>
        </div>
      </div>
    </OnboardingShell>
  );
}

// ─────────────────────────────────────────────────────────────
// 5 · FOCUS AREAS
// ─────────────────────────────────────────────────────────────
function FocusScreen({ theme = 'dark', onNext, onBack }) {
  const p = LIVELY_PALETTE[theme];
  const items = [
    { label: 'Love & relationships', icon: '♡', selected: true },
    { label: 'Career & purpose', icon: '◇', selected: true },
    { label: 'Self-knowledge', icon: '○', selected: false },
    { label: 'Spirituality', icon: '✦', selected: false },
    { label: 'Growth & change', icon: '△', selected: true },
    { label: 'Big life questions', icon: '?', selected: false },
  ];
  return (
    <OnboardingShell
      step={4} theme={theme} onNext={onNext} onBack={onBack}
      kicker="Step 5 · Almost there"
      title={<>What draws you<br/>to the stars?</>}
      subtitle="Pick up to three. Your daily reading and the AI astrologer will lean into these."
      primaryCta="See my chart"
    >
      <div style={{
        display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10,
      }}>
        {items.map((it, i) => (
          <Chip key={i} label={it.label} icon={it.icon} selected={it.selected} theme={theme} />
        ))}
      </div>

      <div style={{ flex: 1 }} />

      <div style={{
        fontSize: 12, color: p.textMuted, textAlign: 'center', marginBottom: 8,
      }}>
        <span style={{ color: p.primary, fontWeight: 600 }}>3</span> of 3 selected
      </div>
    </OnboardingShell>
  );
}

// ─────────────────────────────────────────────────────────────
// WELCOME — the payoff. Chart reveal.
// ─────────────────────────────────────────────────────────────
function WelcomeScreen({ theme = 'dark', onNext, animate = false }) {
  // Stagger reveal — small helper so each block can fade-up with a delay.
  const stagger = (delay) => animate
    ? { animation: `lively-rise .7s ${delay}ms cubic-bezier(.2,.7,.2,1) both` }
    : {};
  const popIn = (delay) => animate
    ? { animation: `lively-scale-in .8s ${delay}ms cubic-bezier(.2,.9,.3,1.05) both` }
    : {};
  const p = LIVELY_PALETTE[theme];
  return (
    <LivelyBackdrop theme={theme} seed={42} intensity={1.4}>
      {/* extra glow behind the wheel */}
      <div style={{
        position: 'absolute', top: 180, left: '50%', width: 360, height: 360,
        transform: 'translateX(-50%)',
        background: `radial-gradient(circle, ${p.primary}22 0%, transparent 60%)`,
        pointerEvents: 'none', filter: 'blur(10px)',
      }} />

      <div style={{
        position: 'absolute', inset: 0,
        padding: `${SAFE.top}px ${SAFE.x}px ${SAFE.bottom}px`,
        display: 'flex', flexDirection: 'column',
      }}>
        {/* tiny intro kicker */}
        <div style={{ textAlign: 'center', marginTop: 4, ...stagger(0) }}>
          <div style={{
            fontSize: 10, letterSpacing: '0.22em', textTransform: 'uppercase',
            color: p.primary, fontWeight: 500,
          }}>
            ✨ Welcome, Alex
          </div>
          <div style={{
            fontSize: 11, color: p.textMuted, marginTop: 6,
            fontFamily: LIVELY_TYPE.mono, letterSpacing: '0.05em',
          }}>
            JULY 28, 1996 · 10:31 AM · ISTANBUL
          </div>
        </div>

        {/* big title */}
        <div style={{
          textAlign: 'center', marginTop: 26,
          fontFamily: LIVELY_TYPE.display, fontStyle: 'italic',
          fontSize: 40, lineHeight: '44px', letterSpacing: '-0.02em',
          color: p.text,
          ...stagger(150),
        }}>
          Your chart<br/>
          <span style={{ color: p.primary }}>is ready.</span>
        </div>

        {/* wheel */}
        <div style={{ display: 'flex', justifyContent: 'center', marginTop: 28, ...popIn(350) }}>
          <MiniWheel size={220} theme={theme} sun="leo" moon="pisces" rising="scorpio" />
        </div>

        {/* luminaries */}
        <div style={{
          marginTop: 28, display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8,
        }}>
          {[
            { kind: 'Sun', sign: 'Leo', glyph: ZODIAC_GLYPHS.leo, hint: 'You shine when' },
            { kind: 'Moon', sign: 'Pisces', glyph: ZODIAC_GLYPHS.pisces, hint: 'You feel through' },
            { kind: 'Rising', sign: 'Scorpio', glyph: ZODIAC_GLYPHS.scorpio, hint: 'You arrive as' },
          ].map((l, i) => (
            <div key={i} style={{
              padding: 12, borderRadius: 14,
              background: theme === 'dark' ? 'rgba(255,255,255,0.04)' : 'rgba(255,255,255,0.7)',
              border: `1px solid ${p.glassBorder}`,
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
              ...stagger(900 + i * 150),
            }}>
              <div style={{
                fontSize: 9, letterSpacing: '0.14em', textTransform: 'uppercase',
                color: p.textMuted, fontWeight: 600,
              }}>{l.kind}</div>
              <div style={{ fontSize: 24, color: p.primary, lineHeight: 1 }}>{l.glyph}</div>
              <div style={{
                fontFamily: LIVELY_TYPE.display, fontStyle: 'italic',
                fontSize: 18, color: p.text, letterSpacing: '-0.01em',
              }}>{l.sign}</div>
            </div>
          ))}
        </div>

        {/* spacer */}
        <div style={{ flex: 1, minHeight: 12 }} />

        {/* opening line */}
        <div style={{
          fontSize: 13.5, lineHeight: '20px', color: p.textMuted, textAlign: 'center',
          maxWidth: 300, margin: '0 auto 18px', fontStyle: 'italic',
          fontFamily: LIVELY_TYPE.display, fontSize: 16,
          ...stagger(1400),
        }}>
          A Leo sun in a Scorpio house — you live loudly,<br/>but you choose carefully.
        </div>

        {/* CTA */}
        <div style={stagger(1600)}>
        <GoldButton theme={theme} onClick={onNext}>
          Enter Lively
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <path d="M3 7 L11 7 M7.5 3 L11 7 L7.5 11" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </GoldButton>
        </div>
      </div>
    </LivelyBackdrop>
  );
}

Object.assign(window, { PlaceScreen, FocusScreen, WelcomeScreen });
