// Lively — root app. Lays out the design canvas with:
//   1. Design system (palette / type / tokens)
//   2. First-impression flow (7 screens × 2 frames where shown)
//
// Tweaks: theme toggle (dark/light), accent intensity, density.

const LIVELY_DEFAULTS = /*EDITMODE-BEGIN*/{
  "theme": "dark",
  "showAndroid": true,
  "starIntensity": 1
}/*EDITMODE-END*/;

function LivelyApp() {
  const [t, setTweak] = useTweaks(LIVELY_DEFAULTS);
  const theme = t.theme;
  const showAndroid = t.showAndroid;

  // Each screen — keyed so we can render uniformly into both iOS and Android.
  const screens = [
    { key: 'auth', title: 'Auth', sub: 'Sign in / Create account', el: <AuthScreen theme={theme} /> },
    { key: 'name', title: '01 · Name', sub: 'Onboarding step 1', el: <NameScreen theme={theme} /> },
    { key: 'date', title: '02 · Date', sub: 'Onboarding step 2', el: <DateScreen theme={theme} /> },
    { key: 'time', title: '03 · Time', sub: 'Onboarding step 3', el: <TimeScreen theme={theme} /> },
    { key: 'place', title: '04 · Place', sub: 'Onboarding step 4', el: <PlaceScreen theme={theme} /> },
    { key: 'focus', title: '05 · Focus', sub: 'Onboarding step 5', el: <FocusScreen theme={theme} /> },
    { key: 'welcome', title: 'Welcome', sub: 'Chart reveal payoff', el: <WelcomeScreen theme={theme} /> },
  ];

  // Artboard sizes — iOS native size, plus header bar.
  const IOS_W = 402, IOS_H = 874;
  const AND_W = 412, AND_H = 892;

  return (
    <>
      <DesignCanvas>
        {/* ───── Interactive prototype ───── */}
        <DCSection id="prototype" title="Interactive prototype · Dark + Light"
          subtitle="Same step state drives both phones. Hit Play to walk the whole flow, or step through with the arrows. Screens fade-lift on transition; the Welcome chart reveals with staggered animation.">
          <DCArtboard id="flow" label="Auth → Onboarding → Welcome" width={920} height={1040}>
            <LivelyFlowPair width={920} height={1040} />
          </DCArtboard>
        </DCSection>

        {/* ───── Intro / context ───── */}
        <DCSection id="brief" title="Lively · cosmic mirror"
          subtitle="A Flutter astrology app. Task 10 (design system) + Task 1 (auth · onboarding · welcome). Dark cosmic is the hero; light iOS toggleable via Tweaks.">
          <BriefCard theme={theme} />
        </DCSection>

        {/* ───── Design system ───── */}
        <DCSection id="ds" title="Design system" subtitle="Palette, type, spacing, radius — the foundation every screen borrows from.">
          <DCArtboard id="palette" label="Palette · both themes" width={720} height={580}>
            <PaletteCard width={720} height={580} />
          </DCArtboard>
          <DCArtboard id="type" label="Type ramp" width={720} height={580}>
            <TypeRampCard width={720} height={580} />
          </DCArtboard>
          <DCArtboard id="tokens" label="Spacing & radius" width={720} height={320}>
            <TokensCard width={720} height={320} />
          </DCArtboard>
          <DCArtboard id="components" label="Components" width={720} height={580}>
            <ComponentsCard theme={theme} />
          </DCArtboard>
        </DCSection>

        {/* ───── iOS row ───── */}
        <DCSection id="ios" title="Task 1 · First impression · iOS"
          subtitle="Auth → 5-step onboarding → Welcome. The progress bar, the gold CTA, and the serif headline travel through every step.">
          {screens.map(s => (
            <DCArtboard key={s.key} id={`ios-${s.key}`} label={s.title} width={IOS_W} height={IOS_H}>
              <IOSDevice width={IOS_W} height={IOS_H} dark={theme === 'dark'}>
                {s.el}
              </IOSDevice>
            </DCArtboard>
          ))}
        </DCSection>

        {/* ───── Android row ───── */}
        {showAndroid && (
          <DCSection id="android" title="Task 1 · First impression · Android"
            subtitle="Same screens, Material 3 chrome. Layout tolerates ~30% longer strings (Turkish).">
            {screens.map(s => (
              <DCArtboard key={s.key} id={`and-${s.key}`} label={s.title} width={AND_W} height={AND_H}>
                <AndroidDevice width={AND_W} height={AND_H} dark={theme === 'dark'}>
                  {s.el}
                </AndroidDevice>
              </DCArtboard>
            ))}
          </DCSection>
        )}
      </DesignCanvas>

      {/* Tweaks panel */}
      <TweaksPanel title="Lively Tweaks">
        <TweakSection label="Theme">
          <TweakRadio
            label="Mode"
            value={theme}
            options={[
              { value: 'dark', label: 'Dark' },
              { value: 'light', label: 'Light' },
            ]}
            onChange={(v) => setTweak('theme', v)}
          />
        </TweakSection>
        <TweakSection label="Canvas">
          <TweakToggle
            label="Show Android row"
            value={showAndroid}
            onChange={(v) => setTweak('showAndroid', v)}
          />
        </TweakSection>
      </TweaksPanel>
    </>
  );
}

// ─────────────────────────────────────────────────────────────
// Brief card — sets the room before designs.
// ─────────────────────────────────────────────────────────────
function BriefCard({ theme }) {
  const p = LIVELY_PALETTE[theme];
  return (
    <div style={{
      width: 980, padding: 32,
      background: p.bg, color: p.text, borderRadius: 18,
      fontFamily: LIVELY_TYPE.ui, position: 'relative', overflow: 'hidden',
      border: `1px solid ${p.line}`,
    }}>
      {/* subtle starfield in the corner */}
      <div style={{ position: 'absolute', top: 0, right: 0, width: 320, height: '100%', opacity: 0.6 }}>
        <LivelyBackdrop theme={theme} seed={3} intensity={0.4} />
      </div>

      <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: 12 }}>
        <LivelyMark size={28} color={p.primary} ring={p.glassBorder} />
        <LivelyWordmark size={26} color={p.text} />
        <div style={{ color: p.textMuted, fontSize: 13, marginLeft: 8 }}>
          · Western · Vedic · Numerology · Human Design
        </div>
      </div>

      <div style={{
        position: 'relative', marginTop: 22,
        fontFamily: LIVELY_TYPE.display, fontStyle: 'italic',
        fontSize: 38, lineHeight: '42px', letterSpacing: '-0.02em',
        maxWidth: 620,
      }}>
        Premium and emotionally intelligent.<br />
        <span style={{ color: p.primary }}>Not mystical-kitsch.</span>
      </div>

      <div style={{ position: 'relative', marginTop: 28, display: 'flex', gap: 32, flexWrap: 'wrap' }}>
        {[
          { k: 'Accent', v: '#D4B16A', n: 'bronze-gold' },
          { k: 'Display', v: 'Instrument Serif', n: 'italic, editorial' },
          { k: 'UI', v: 'Geist', n: 'modern grotesque' },
          { k: 'Themes', v: 'Dark · Light', n: 'AppPalette tokens' },
          { k: 'Locales', v: 'EN · TR', n: '+30% string headroom' },
        ].map(x => (
          <div key={x.k}>
            <div style={{ fontSize: 10, letterSpacing: '0.14em', textTransform: 'uppercase', color: p.textMuted, marginBottom: 4 }}>
              {x.k}
            </div>
            <div style={{ fontSize: 15, fontWeight: 500, color: p.text }}>{x.v}</div>
            <div style={{ fontSize: 11, color: p.textMuted, marginTop: 2 }}>{x.n}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Components — buttons + cards + chips + form fields, all variants.
// ─────────────────────────────────────────────────────────────
function ComponentsCard({ theme }) {
  const p = LIVELY_PALETTE[theme];
  const w = 720, h = 580;
  return (
    <div style={{
      width: w, height: h, background: p.bg, color: p.text,
      padding: 28, fontFamily: LIVELY_TYPE.ui, borderRadius: 16,
      display: 'flex', flexDirection: 'column', gap: 22, overflow: 'hidden',
    }}>
      <div>
        <div style={{ fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase', color: p.textMuted }}>
          Components
        </div>
        <div style={{ fontFamily: LIVELY_TYPE.display, fontStyle: 'italic', fontSize: 26, color: p.primary, marginTop: 4 }}>
          The kit, in one place
        </div>
      </div>

      {/* Buttons */}
      <div>
        <Label theme={theme}>Buttons</Label>
        <div style={{ display: 'flex', gap: 12, marginTop: 10, alignItems: 'center' }}>
          <div style={{ width: 180 }}>
            <GoldButton theme={theme}>Continue</GoldButton>
          </div>
          <div style={{ width: 180 }}>
            <GoldButton theme={theme} ghost>Skip</GoldButton>
          </div>
          <div style={{ width: 120 }}>
            <GoldButton theme={theme} small>Small</GoldButton>
          </div>
        </div>
      </div>

      {/* Form fields */}
      <div>
        <Label theme={theme}>Form fields · fill = page bg</Label>
        <div style={{ marginTop: 10, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          <FormField theme={theme} label="Default" value="" placeholder="Enter email" />
          <FormField theme={theme} label="Filled · focused" value="alex@lively.app" focused />
        </div>
      </div>

      {/* Chips */}
      <div>
        <Label theme={theme}>Chips</Label>
        <div style={{ display: 'flex', gap: 10, marginTop: 10, flexWrap: 'wrap' }}>
          <Chip theme={theme} label="Love" icon="♡" selected />
          <Chip theme={theme} label="Career" icon="◇" />
          <Chip theme={theme} label="Spirituality" icon="✦" />
          <Chip theme={theme} label="Growth" icon="△" />
        </div>
      </div>

      {/* Progress */}
      <div>
        <Label theme={theme}>Step progress · 5-step</Label>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginTop: 10, maxWidth: 220 }}>
          <StepProgress theme={theme} step={0} />
          <StepProgress theme={theme} step={2} />
          <StepProgress theme={theme} step={4} />
        </div>
      </div>

      {/* Glass card */}
      <div>
        <Label theme={theme}>Glass card</Label>
        <div style={{ display: 'flex', gap: 12, marginTop: 10 }}>
          <GlassCard theme={theme} style={{ flex: 1, maxWidth: 260 }}>
            <div style={{ fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase', color: p.textMuted }}>
              Today
            </div>
            <div style={{ fontFamily: LIVELY_TYPE.display, fontStyle: 'italic', fontSize: 22, marginTop: 4 }}>
              The moon turns inward
            </div>
            <div style={{ fontSize: 12.5, color: p.textMuted, marginTop: 6, lineHeight: '18px' }}>
              A reflective day for Leos. Notice what you reach for when no one’s watching.
            </div>
          </GlassCard>
        </div>
      </div>
    </div>
  );
}

function Label({ theme, children }) {
  const p = LIVELY_PALETTE[theme];
  return (
    <div style={{
      fontSize: 10, letterSpacing: '0.14em', textTransform: 'uppercase',
      color: p.textMuted, fontWeight: 500,
    }}>{children}</div>
  );
}

Object.assign(window, { LivelyApp, BriefCard, ComponentsCard });
