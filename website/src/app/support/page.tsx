import type { Metadata } from "next";
import { PageShell } from "@/components/PageShell";

export const metadata: Metadata = {
  title: "Support & Help — Lively",
  description:
    "Get help with Lively — how your chart is calculated, managing your subscription, restoring purchases, exporting your data, deleting your account, and how to reach us at hello@livelyapp.co.",
  alternates: { canonical: "/support" },
  openGraph: {
    title: "Support & Help — Lively",
    description: "Answers to common questions and how to contact the Lively team.",
    type: "website",
  },
};

const LAST_UPDATED = "6 July 2026";

export default function SupportPage() {
  return (
    <PageShell
      eyebrow="Help Center"
      title={
        <>
          Support &amp; <span className="text-gold-gradient">Help</span>
        </>
      }
      lastUpdated={LAST_UPDATED}
      intro="Answers to the questions we hear most. Can't find what you need? We're a short email away."
    >
      <div className="legal-callout">
        <p>
          <strong>Need a hand?</strong> Email us at{" "}
          <a href="mailto:hello@livelyapp.co">hello@livelyapp.co</a> and a real
          person will get back to you, usually within 1&ndash;2 business days.
          Please include your account email and, if reporting a bug, your device
          model and app version.
        </p>
      </div>

      <h2 id="faq">Frequently asked questions</h2>

      <h3 id="chart">How is my chart calculated?</h3>
      <p>
        Lively uses your <strong>date, time, and place of birth</strong> to
        compute your Western natal chart, Vedic charts, numerology numbers, and
        Human Design body graph using established astronomical and astrological
        methods. The more precise your birth details — especially your exact
        birth time — the more accurate your houses and rising sign will be.
      </p>

      <h3 id="birth-time">I don&rsquo;t know my exact birth time. Can I still use Lively?</h3>
      <p>
        Yes. You can still explore most of the App without an exact time. Some
        placements that depend on time — such as your Ascendant (rising sign),
        house positions, and the Moon&rsquo;s exact degree — may be approximate
        or unavailable. If you later find your birth time (it&rsquo;s often on
        your birth certificate), you can update it in{" "}
        <em>Settings &rarr; Birth details</em> and your charts will recalculate.
      </p>

      <h3 id="free-vs-premium">What&rsquo;s the difference between Free and Premium?</h3>
      <p>
        The <strong>Free</strong> tier includes your core Western chart, the
        Vedic Rasi chart, your main numerology numbers, a daily reading, a
        limited number of AI astrologer messages per day, and access to public
        community spaces. <strong>Premium</strong> unlocks the full Vedic
        toolkit (all vargas, dashas, yogas, and more), the complete Human Design
        body graph, unlimited AI astrologer chat, unlimited compatibility
        reports, the Cosmic Timeline forecasts, tailored rituals and journal
        prompts, and an ad-free experience. See{" "}
        <a href="/#pricing">pricing</a> for the latest details.
      </p>

      <h3 id="subscription">How do I manage or cancel my subscription?</h3>
      <p>
        Subscriptions are billed through your app store, so you manage them
        there. Cancelling stops future renewals; you keep Premium until the end
        of your paid period.
      </p>
      <ul>
        <li>
          <strong>iPhone / iPad (App Store):</strong> Open{" "}
          <em>Settings</em> &rarr; tap your name &rarr; <em>Subscriptions</em>{" "}
          &rarr; select <em>Lively</em> &rarr; <em>Cancel Subscription</em>.
        </li>
        <li>
          <strong>Android (Google Play):</strong> Open the{" "}
          <em>Play Store</em> app &rarr; tap your profile icon &rarr;{" "}
          <em>Payments &amp; subscriptions</em> &rarr; <em>Subscriptions</em>{" "}
          &rarr; select <em>Lively</em> &rarr; <em>Cancel subscription</em>.
        </li>
      </ul>
      <p>
        Note that deleting the App does not cancel your subscription — you must
        cancel through the app store.
      </p>

      <h3 id="restore">How do I restore my purchases?</h3>
      <p>
        If you reinstalled the App or switched to a new device using the same
        app store account, open <em>Settings &rarr; Subscription</em> and tap{" "}
        <strong>Restore Purchases</strong>. Make sure you are signed in with the
        same Apple ID or Google account you used to subscribe.
      </p>

      <h3 id="export">How do I export my data?</h3>
      <p>
        You can request a copy of your personal data — including your birth
        details, journal entries, and account information — from{" "}
        <em>Settings &rarr; Account &rarr; Export my data</em>, or by emailing{" "}
        <a href="mailto:hello@livelyapp.co">hello@livelyapp.co</a> from your
        account email. See our <a href="/privacy#your-rights">Privacy Policy</a>{" "}
        for the full list of your rights.
      </p>

      <h3 id="delete">How do I delete my account and data?</h3>
      <p>
        Go to <em>Settings &rarr; Account &rarr; Delete account</em> in the App
        and confirm. This permanently deletes your account and removes your
        personal data from our systems within <strong>30 days</strong>. If you
        can&rsquo;t access the App, email{" "}
        <a href="mailto:hello@livelyapp.co">hello@livelyapp.co</a> from your
        account email and we&rsquo;ll take care of it. Deleting your account
        does not automatically cancel a subscription — cancel it in your app
        store first (see above).
      </p>

      <h3 id="privacy">Is my data private? Does the AI see my information?</h3>
      <p>
        We take your privacy seriously and we never sell your data. To answer
        your questions, the AI astrologer sends the relevant message and
        astrological context to our AI provider (OpenAI) to generate a reply.
        Full details are in our <a href="/privacy">Privacy Policy</a>.
      </p>

      <h3 id="ai-limits">Why won&rsquo;t the AI answer my medical, legal, or financial question?</h3>
      <p>
        Lively is for <strong>entertainment and self-reflection only</strong>.
        The AI astrologer is designed to decline medical, legal, financial, and
        crisis-related requests and to point you toward a qualified professional
        instead. If you are in crisis or facing an emergency, please contact
        your local emergency services or a crisis helpline right away. See our{" "}
        <a href="/terms#entertainment">Terms of Service</a> for more.
      </p>

      <h2 id="contact">Still need help?</h2>
      <p>
        Reach out any time and we&rsquo;ll do our best to help:
      </p>
      <ul>
        <li>
          <strong>Email:</strong>{" "}
          <a href="mailto:hello@livelyapp.co">hello@livelyapp.co</a>
        </li>
        <li>
          <strong>Privacy &amp; data requests:</strong>{" "}
          <a href="mailto:hello@livelyapp.co">hello@livelyapp.co</a>
        </li>
        <li>
          <strong>Response time:</strong> usually within 1&ndash;2 business days.
        </li>
      </ul>
    </PageShell>
  );
}
