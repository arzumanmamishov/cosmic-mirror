// Lively — interactive prototype.
// Same step state drives a Dark phone and a Light phone side-by-side.
// Transitions: screen fades + lifts when step changes.

function LivelyFlowPair({ width = 920, height = 1040 }) {
  const TOTAL = 7;
  const labels = ['Auth', '01 Name', '02 Date', '03 Time', '04 Place', '05 Focus', 'Welcome'];

  const [step, setStep] = React.useState(0);
  const [playing, setPlaying] = React.useState(false);
  const next = React.useCallback(() => setStep(s => (s + 1) % TOTAL), []);
  const prev = React.useCallback(() => setStep(s => (s - 1 + TOTAL) % TOTAL), []);
  const reset = React.useCallback(() => setStep(0), []);

  // Auto-play through the flow on a 2.6s cadence; stop at Welcome.
  React.useEffect(() => {
    if (!playing) return undefined;
    if (step >= TOTAL - 1) { setPlaying(false); return undefined; }
    const t = setTimeout(next, 2600);
    return () => clearTimeout(t);
  }, [playing, step, next]);

  return (
    <div style={{
      width, height, background: '#1A1A22', borderRadius: 18,
      padding: 24, fontFamily: LIVELY_TYPE.ui,
      display: 'flex', flexDirection: 'column', gap: 18, overflow: 'hidden',
      position: 'relative',
    }}>
      {/* faint cosmic backdrop behind the controls — sets the mood */}
      <div style={{
        position: 'absolute', inset: 0,
        background: 'radial-gradient(ellipse 80% 60% at 50% 0%, rgba(212,177,106,0.08), transparent 70%)',
        pointerEvents: 'none',
      }} />

      <FlowControls
        step={step} total={TOTAL} labels={labels}
        onNext={next} onPrev={prev} onReset={reset}
        playing={playing} setPlaying={setPlaying}
      />

      <div style={{
        flex: 1, display: 'flex', gap: 32, justifyContent: 'center', alignItems: 'flex-start',
        paddingTop: 8, position: 'relative',
      }}>
        <FlowPhone theme="dark" step={step} onNext={next} onBack={prev} onRestart={reset} />
        <FlowPhone theme="light" step={step} onNext={next} onBack={prev} onRestart={reset} />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Controls: step labels + transport.
// ─────────────────────────────────────────────────────────────
function FlowControls({ step, total, labels, onNext, onPrev, onReset, playing, setPlaying }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 16, position: 'relative',
      color: '#F2EBD9',
    }}>
      {/* step pills */}
      <div style={{ display: 'flex', gap: 6, flex: 1, flexWrap: 'wrap' }}>
        {labels.map((l, i) => {
          const active = i === step;
          const done = i < step;
          return (
            <div key={i} style={{
              padding: '6px 12px', borderRadius: 999,
              fontSize: 11, fontWeight: 500, letterSpacing: '0.04em',
              background: active ? '#D4B16A' : (done ? 'rgba(212,177,106,0.16)' : 'rgba(255,255,255,0.05)'),
              color: active ? '#1A1408' : (done ? '#D4B16A' : '#A09989'),
              border: active ? 'none' : `1px solid ${done ? 'rgba(212,177,106,0.3)' : 'rgba(255,255,255,0.06)'}`,
              transition: 'all .3s',
            }}>
              {l}
            </div>
          );
        })}
      </div>

      {/* transport */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <CtrlBtn onClick={onPrev} disabled={step === 0} title="Previous">
          <svg width="14" height="14" viewBox="0 0 14 14"><path d="M9 2 L4 7 L9 12" stroke="currentColor" strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </CtrlBtn>
        <CtrlBtn onClick={() => setPlaying(p => !p)} primary title={playing ? 'Pause' : 'Play through flow'}>
          {playing
            ? <svg width="12" height="12" viewBox="0 0 12 12"><rect x="3" y="2" width="2.5" height="8" rx="0.5" fill="currentColor"/><rect x="6.5" y="2" width="2.5" height="8" rx="0.5" fill="currentColor"/></svg>
            : <svg width="12" height="12" viewBox="0 0 12 12"><path d="M3 2 L10 6 L3 10 Z" fill="currentColor"/></svg>
          }
        </CtrlBtn>
        <CtrlBtn onClick={onNext} disabled={step === total - 1} title="Next">
          <svg width="14" height="14" viewBox="0 0 14 14"><path d="M5 2 L10 7 L5 12" stroke="currentColor" strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </CtrlBtn>
        <div style={{ width: 1, height: 24, background: 'rgba(255,255,255,0.08)', margin: '0 4px' }} />
        <CtrlBtn onClick={onReset} title="Restart">
          <svg width="14" height="14" viewBox="0 0 14 14"><path d="M3 7 a4 4 0 1 0 1.2 -2.8 M3 2 L3 5 L6 5" stroke="currentColor" strokeWidth="1.4" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </CtrlBtn>
      </div>
    </div>
  );
}

function CtrlBtn({ children, onClick, primary, disabled, title }) {
  return (
    <button onClick={onClick} disabled={disabled} title={title} className="lively-press" style={{
      width: 32, height: 32, borderRadius: 10, border: 'none', cursor: disabled ? 'default' : 'pointer',
      background: primary ? '#D4B16A' : 'rgba(255,255,255,0.06)',
      color: primary ? '#1A1408' : (disabled ? '#5A5346' : '#F2EBD9'),
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      opacity: disabled ? 0.5 : 1, transition: 'background .15s',
    }}>{children}</button>
  );
}

// ─────────────────────────────────────────────────────────────
// One phone — renders the current screen with an enter animation.
// ─────────────────────────────────────────────────────────────
function FlowPhone({ theme, step, onNext, onBack, onRestart }) {
  const screens = [
    <AuthScreen theme={theme} onNext={onNext} />,
    <NameScreen theme={theme} onNext={onNext} onBack={onBack} />,
    <DateScreen theme={theme} onNext={onNext} onBack={onBack} />,
    <TimeScreen theme={theme} onNext={onNext} onBack={onBack} />,
    <PlaceScreen theme={theme} onNext={onNext} onBack={onBack} />,
    <FocusScreen theme={theme} onNext={onNext} onBack={onBack} />,
    <WelcomeScreen theme={theme} animate onNext={onRestart} />,
  ];

  return (
    <div style={{ position: 'relative', filter: 'drop-shadow(0 30px 60px rgba(0,0,0,0.4))' }}>
      <IOSDevice width={402} height={874} dark={theme === 'dark'}>
        {/* keyed wrapper triggers re-mount + enter animation on step change */}
        <div key={`${theme}-${step}`} className="lively-screen-enter" style={{ position: 'absolute', inset: 0 }}>
          {screens[step]}
        </div>
      </IOSDevice>
      {/* theme label tag */}
      <div style={{
        position: 'absolute', top: -8, left: 20,
        padding: '4px 10px', borderRadius: 999,
        background: theme === 'dark' ? '#13131C' : '#FFFFFF',
        border: `1px solid ${theme === 'dark' ? 'rgba(212,177,106,0.3)' : 'rgba(168,133,70,0.3)'}`,
        color: theme === 'dark' ? '#D4B16A' : '#A88546',
        fontSize: 10, fontWeight: 600, letterSpacing: '0.12em', textTransform: 'uppercase',
      }}>
        {theme === 'dark' ? 'Dark · Cosmic' : 'Light · iOS'}
      </div>
    </div>
  );
}

Object.assign(window, { LivelyFlowPair, FlowControls, FlowPhone, CtrlBtn });
