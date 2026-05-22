// Lively — first-impression screens.
// Each exports a (theme) => JSX screen body that lives inside an
// IOSDevice (and reuses the same body inside an AndroidDevice).

// Safe-area padding: enough to clear the status bar (50) and home indicator (34).
const SAFE = { top: 56, bottom: 50, x: 24 };

// ─────────────────────────────────────────────────────────────
// AUTH — entry point
// ─────────────────────────────────────────────────────────────
function AuthScreen({ theme = 'dark', onNext }) {
  const p = LIVELY_PALETTE[theme];
  return (
    <LivelyBackdrop theme={theme} seed={11} intensity={1}>
      <div style={{
        position: 'absolute', inset: 0, padding: `${SAFE.top}px ${SAFE.x}px ${SAFE.bottom}px`,
        display: 'flex', flexDirection: 'column',
      }}>
        {/* logo lockup */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 6 }}>
          <LivelyMark size={26} color={p.primary} ring={p.glassBorder} />
          <LivelyWordmark size={22} color={p.text} />
        </div>

        {/* hero */}
        <div style={{ marginTop: 88, display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div style={{
            fontSize: 11, letterSpacing: '0.18em', textTransform: 'uppercase',
            color: p.primary, fontWeight: 500,
          }}>
            Welcome back
          </div>
          <div style={{
            fontFamily: LIVELY_TYPE.display, fontSize: 46, lineHeight: '50px',
            fontStyle: 'italic', letterSpacing: '-0.02em', color: p.text,
          }}>
            The sky,<br/>made personal.
          </div>
          <div style={{
            fontSize: 14, color: p.textMuted, lineHeight: '20px',
            marginTop: 6, maxWidth: 280,
          }}>
            Sign in to your charts, journal, and the daily reading written for you.
          </div>
        </div>

        {/* spacer pushes form to bottom-ish */}
        <div style={{ flex: 1 }} />

        {/* form */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <FormField
            theme={theme} label="Email"
            value="alex@lively.app"
            focused={false}
          />
          <FormField
            theme={theme} label="Password"
            value="••••••••••"
            suffix={
              <span style={{ fontSize: 12, color: p.primary, fontWeight: 500 }}>Forgot</span>
            }
          />
          <div style={{ height: 4 }} />
          <GoldButton theme={theme} onClick={onNext}>Continue</GoldButton>

          {/* divider */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '10px 0' }}>
            <div style={{ flex: 1, height: 1, background: p.line }} />
            <div style={{ fontSize: 11, letterSpacing: '0.1em', color: p.textMuted, textTransform: 'uppercase' }}>
              or
            </div>
            <div style={{ flex: 1, height: 1, background: p.line }} />
          </div>

          {/* socials */}
          <div style={{ display: 'flex', gap: 10 }}>
            <SocialBtn theme={theme} kind="apple" />
            <SocialBtn theme={theme} kind="google" />
          </div>

          <div style={{
            textAlign: 'center', marginTop: 14, fontSize: 13, color: p.textMuted,
          }}>
            New to Lively? <span style={{ color: p.primary, fontWeight: 600 }}>Create account</span>
          </div>
        </div>
      </div>
    </LivelyBackdrop>
  );
}

function SocialBtn({ theme, kind }) {
  const p = LIVELY_PALETTE[theme];
  const icon = kind === 'apple' ? (
    <svg width="16" height="18" viewBox="0 0 16 18" fill={p.text}>
      <path d="M11.6 9.6c0-2 1.6-3 1.7-3-.9-1.4-2.4-1.6-2.9-1.6-1.2-.1-2.4.7-3 .7-.6 0-1.6-.7-2.6-.7-1.3 0-2.6.8-3.3 2-1.4 2.5-.4 6.1 1 8.1.7 1 1.5 2.1 2.5 2 1 0 1.4-.6 2.6-.6 1.2 0 1.5.6 2.6.6 1 0 1.7-1 2.4-2 .8-1.1 1.1-2.2 1.1-2.3-.1 0-2.1-.8-2.1-3.2zM9.6 3.6c.5-.6.9-1.5.8-2.4-.8 0-1.7.5-2.3 1.2-.5.6-1 1.5-.8 2.4.9.1 1.8-.5 2.3-1.2z"/>
    </svg>
  ) : (
    <svg width="17" height="17" viewBox="0 0 17 17">
      <path d="M16.3 8.7c0-.6 0-1.1-.1-1.7H8.3v3.2h4.5c-.2 1.1-.8 2-1.7 2.6v2.1h2.7c1.6-1.5 2.5-3.7 2.5-6.2z" fill="#4285F4"/>
      <path d="M8.3 17c2.3 0 4.2-.8 5.6-2.1l-2.7-2.1c-.8.5-1.7.8-2.9.8-2.2 0-4.1-1.5-4.8-3.5H.7v2.2C2.1 14.9 5 17 8.3 17z" fill="#34A853"/>
      <path d="M3.5 10.1c-.2-.5-.3-1.1-.3-1.6 0-.5.1-1.1.3-1.6V4.7H.7C.2 5.8 0 6.9 0 8.5s.2 2.7.7 3.8l2.8-2.2z" fill="#FBBC05"/>
      <path d="M8.3 3.4c1.3 0 2.4.4 3.3 1.3l2.4-2.4C12.5.8 10.6 0 8.3 0 5 0 2.1 2.1.7 4.7l2.8 2.2c.7-2 2.6-3.5 4.8-3.5z" fill="#EA4335"/>
    </svg>
  );
  return (
    <div style={{
      flex: 1, padding: '13px 0', borderRadius: 14,
      background: theme === 'dark' ? 'rgba(255,255,255,0.05)' : '#fff',
      border: `1px solid ${p.line}`,
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      fontFamily: LIVELY_TYPE.ui, fontSize: 14, fontWeight: 500, color: p.text,
    }}>
      {icon}
      <span>{kind === 'apple' ? 'Apple' : 'Google'}</span>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Reusable onboarding shell — header + progress + body + footer.
// ─────────────────────────────────────────────────────────────
function OnboardingShell({ step, theme = 'dark', kicker, title, subtitle, children, primaryCta = 'Continue', tertiary, onNext, onBack }) {
  const p = LIVELY_PALETTE[theme];
  return (
    <LivelyBackdrop theme={theme} seed={5 + step} intensity={0.6}>
      <div style={{
        position: 'absolute', inset: 0,
        padding: `${SAFE.top}px ${SAFE.x}px ${SAFE.bottom}px`,
        display: 'flex', flexDirection: 'column',
      }}>
        {/* progress + back */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <div onClick={onBack} className="lively-press" style={{
            width: 32, height: 32, borderRadius: 999,
            background: theme === 'dark' ? 'rgba(255,255,255,0.04)' : '#fff',
            border: `1px solid ${p.line}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: onBack ? 'pointer' : 'default',
          }}>
            <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
              <path d="M8 2 L3 6 L8 10" stroke={p.text} strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </div>
          <div style={{ flex: 1 }}>
            <StepProgress step={step} total={5} theme={theme} />
          </div>
          <div style={{ fontSize: 11, color: p.textMuted, fontFamily: LIVELY_TYPE.mono, letterSpacing: '0.06em' }}>
            {step + 1} / 5
          </div>
        </div>

        {/* heading */}
        <div style={{ marginTop: 44 }}>
          {kicker && (
            <div style={{
              fontSize: 11, letterSpacing: '0.18em', textTransform: 'uppercase',
              color: p.primary, fontWeight: 500, marginBottom: 12,
            }}>{kicker}</div>
          )}
          <div style={{
            fontFamily: LIVELY_TYPE.display, fontSize: 38, lineHeight: '42px',
            fontStyle: 'italic', letterSpacing: '-0.02em', color: p.text,
          }}>{title}</div>
          {subtitle && (
            <div style={{
              marginTop: 12, fontSize: 14, color: p.textMuted, lineHeight: '20px',
              maxWidth: 300,
            }}>{subtitle}</div>
          )}
        </div>

        {/* body */}
        <div style={{ flex: 1, marginTop: 28, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
          {children}
        </div>

        {/* footer */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {tertiary && (
            <div style={{ textAlign: 'center', fontSize: 13, color: p.textMuted }}>
              {tertiary}
            </div>
          )}
          <GoldButton theme={theme} onClick={onNext}>
            {primaryCta}
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none" style={{ marginLeft: 2 }}>
              <path d="M3 7 L11 7 M7.5 3 L11 7 L7.5 11" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </GoldButton>
        </div>
      </div>
    </LivelyBackdrop>
  );
}

// ─────────────────────────────────────────────────────────────
// 1 · NAME
// ─────────────────────────────────────────────────────────────
function NameScreen({ theme = 'dark', onNext, onBack }) {
  return (
    <OnboardingShell
      step={0} theme={theme} onNext={onNext} onBack={onBack}
      kicker="Step 1"
      title={<>What should we<br/>call you?</>}
      subtitle="Your readings are written for a person, not a profile. First name is fine."
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
        <FormField theme={theme} label="First name" value="Alex" large focused />
        <div style={{
          fontSize: 12, color: LIVELY_PALETTE[theme].textMuted, paddingLeft: 4,
        }}>
          We’ll never share this. Change it any time in Profile.
        </div>
      </div>
    </OnboardingShell>
  );
}

// ─────────────────────────────────────────────────────────────
// 2 · DATE OF BIRTH — iOS-style wheel picker
// ─────────────────────────────────────────────────────────────
function DateScreen({ theme = 'dark', onNext, onBack }) {
  return (
    <OnboardingShell
      step={1} theme={theme} onNext={onNext} onBack={onBack}
      kicker="Step 2 · Birth date"
      title={<>When were<br/>you born?</>}
      subtitle="Your sun sign and the season of your birth start here."
    >
      <WheelPicker theme={theme} columns={[
        { label: 'Month', values: ['May', 'Jun', 'Jul', 'Aug', 'Sep'], active: 2 },
        { label: 'Day', values: ['26', '27', '28', '29', '30'], active: 2 },
        { label: 'Year', values: ['1994', '1995', '1996', '1997', '1998'], active: 2 },
      ]} />
    </OnboardingShell>
  );
}

// ─────────────────────────────────────────────────────────────
// 3 · TIME OF BIRTH
// ─────────────────────────────────────────────────────────────
function TimeScreen({ theme = 'dark', onNext, onBack }) {
  const p = LIVELY_PALETTE[theme];
  return (
    <OnboardingShell
      step={2} theme={theme} onNext={onNext} onBack={onBack}
      kicker="Step 3 · Birth time"
      title={<>And the hour?</>}
      subtitle="Your rising sign and the houses depend on the exact minute. Within 15 minutes is great."
      tertiary={<span>I don’t know <span style={{ color: p.primary, fontWeight: 600 }}>· Use sunrise</span></span>}
    >
      <WheelPicker theme={theme} columns={[
        { label: 'Hour', values: ['9', '10', '11', '12', '1'], active: 2 },
        { label: 'Min', values: ['28', '29', '30', '31', '32'], active: 2 },
        { label: '', values: ['', '', 'AM', 'PM', ''], active: 2 },
      ]} />

      <div style={{
        marginTop: 18, padding: '14px 16px', display: 'flex', gap: 12,
        background: theme === 'dark' ? 'rgba(212,177,106,0.07)' : 'rgba(168,133,70,0.08)',
        borderRadius: 14, border: `1px solid ${p.glassBorder}`, alignItems: 'flex-start',
      }}>
        <div style={{ fontSize: 16 }}>✨</div>
        <div style={{ fontSize: 12.5, lineHeight: '18px', color: p.textMuted }}>
          Birth certificates have it. So do most baby books. A four-minute difference can change your Ascendant by a whole sign.
        </div>
      </div>
    </OnboardingShell>
  );
}

// Wheel picker — three-column scroll wheel, iOS-pattern.
function WheelPicker({ theme = 'dark', columns }) {
  const p = LIVELY_PALETTE[theme];
  return (
    <div style={{
      background: theme === 'dark' ? 'rgba(255,255,255,0.03)' : '#fff',
      border: `1px solid ${p.line}`,
      borderRadius: 18, padding: '8px 12px', position: 'relative',
      height: 220, display: 'flex',
    }}>
      {/* highlighted center band */}
      <div style={{
        position: 'absolute', left: 8, right: 8, top: '50%', height: 44,
        transform: 'translateY(-50%)',
        background: theme === 'dark' ? 'rgba(212,177,106,0.10)' : 'rgba(168,133,70,0.10)',
        border: `1px solid ${p.glassBorder}`,
        borderRadius: 10,
      }} />
      {columns.map((col, ci) => (
        <div key={ci} style={{
          flex: 1, position: 'relative', display: 'flex', flexDirection: 'column',
          justifyContent: 'center', alignItems: 'center', overflow: 'hidden',
        }}>
          {col.values.map((v, vi) => {
            const dist = Math.abs(vi - col.active);
            const opacity = 1 - dist * 0.28;
            const scale = 1 - dist * 0.07;
            const active = vi === col.active;
            return (
              <div key={vi} style={{
                fontFamily: LIVELY_TYPE.ui,
                fontSize: 22, fontWeight: active ? 600 : 400,
                color: active ? p.primary : p.text,
                opacity, transform: `scale(${scale})`,
                height: 40, display: 'flex', alignItems: 'center', justifyContent: 'center',
                letterSpacing: '-0.01em',
              }}>{v}</div>
            );
          })}
          {col.label && (
            <div style={{
              position: 'absolute', bottom: 6, left: 0, right: 0,
              fontSize: 10, letterSpacing: '0.12em', textTransform: 'uppercase',
              color: p.textMuted, textAlign: 'center',
            }}>{col.label}</div>
          )}
        </div>
      ))}
    </div>
  );
}

Object.assign(window, { AuthScreen, NameScreen, DateScreen, TimeScreen, OnboardingShell, WheelPicker, SocialBtn, SAFE });
