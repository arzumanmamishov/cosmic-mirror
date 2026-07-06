/* <!-- TEMPLATE: review by legal counsel before production launch. Placeholders: governing-law jurisdiction, company legal entity name. --> */
import type { Metadata } from "next";
import { PageShell } from "@/components/PageShell";

export const metadata: Metadata = {
  title: "Privacy Policy — Lively",
  description:
    "How Lively collects, uses, and protects your data — including your birth details, journal entries, and AI astrologer conversations. Your data is never sold.",
  alternates: { canonical: "/privacy" },
  openGraph: {
    title: "Privacy Policy — Lively",
    description:
      "How Lively collects, uses, and protects your personal data.",
    type: "website",
  },
};

const LAST_UPDATED = "6 July 2026";

export default function PrivacyPage() {
  return (
    <PageShell
      eyebrow="Legal"
      title={
        <>
          Privacy <span className="text-gold-gradient">Policy</span>
        </>
      }
      lastUpdated={LAST_UPDATED}
      intro="Your birth chart is deeply personal. This policy explains, in plain language, exactly what Lively collects, why, who we share it with, and the rights you have over your data."
    >
      <p>
        This Privacy Policy describes how <strong>[Company Legal Entity]</strong>{" "}
        (&ldquo;Lively,&rdquo; &ldquo;we,&rdquo; &ldquo;us,&rdquo; or
        &ldquo;our&rdquo;) collects, uses, and safeguards your information when
        you use the Lively mobile application (the &ldquo;App&rdquo;) and the
        website at{" "}
        <a href="https://livelyapp.co">livelyapp.co</a> (together, the
        &ldquo;Service&rdquo;). It applies to everyone who uses Lively,
        wherever you are located. By using the Service you agree to the
        practices described here.
      </p>
      <p>
        If you have any questions, you can always reach a human at{" "}
        <a href="mailto:hello@livelyapp.co">hello@livelyapp.co</a>.
      </p>

      <h2 id="data-we-collect">1. Information we collect</h2>
      <p>We only collect what we need to give you accurate readings and run the Service.</p>

      <h3>Information you give us</h3>
      <ul>
        <li>
          <strong>Account information.</strong> Your email address and
          authentication identifiers when you create an account or sign in.
        </li>
        <li>
          <strong>Birth details.</strong> Your date of birth, exact time of
          birth (where known), and place of birth (city and/or geographic
          coordinates). This data is used solely to calculate your Western
          natal chart, Vedic charts, numerology numbers, and Human Design body
          graph. It is the astrological heart of the App.
        </li>
        <li>
          <strong>Journal entries and rituals.</strong> Any notes, reflections,
          moods, or ritual progress you record inside the App.
        </li>
        <li>
          <strong>AI astrologer conversations.</strong> The messages you send to
          the in-app AI astrologer and the readings it generates for you.
        </li>
        <li>
          <strong>Compatibility data.</strong> If you create a compatibility
          report, the name and birth details you enter for another person. Only
          add someone else&rsquo;s details if you have their permission to do
          so.
        </li>
        <li>
          <strong>Support correspondence.</strong> The contents of any messages
          you send us for support or feedback.
        </li>
      </ul>

      <h3>Information we collect automatically</h3>
      <ul>
        <li>
          <strong>Usage analytics.</strong> Which features you use, screens you
          view, and general interaction patterns, so we can improve the App.
        </li>
        <li>
          <strong>Device &amp; diagnostic data.</strong> Device model, operating
          system version, app version, language, approximate region, and crash
          / error logs.
        </li>
        <li>
          <strong>Subscription status.</strong> Whether you are on the free or
          premium tier, your plan, trial status, and renewal state. We do{" "}
          <strong>not</strong> receive or store your full payment card number —
          that is handled by the app stores and payment processors below.
        </li>
      </ul>

      <h2 id="how-we-use">2. How we use your information</h2>
      <ul>
        <li>To calculate and display your charts, numbers, and readings.</li>
        <li>To power the AI astrologer and generate personalized content.</li>
        <li>To create, secure, and manage your account.</li>
        <li>To process subscriptions and provide premium features.</li>
        <li>To send you service messages and, if enabled, push notifications such as your daily reading.</li>
        <li>To provide customer support and respond to your requests.</li>
        <li>To monitor stability, prevent abuse and fraud, and improve the Service.</li>
        <li>To comply with our legal obligations.</li>
      </ul>

      <h2 id="legal-bases">3. Legal bases for processing (GDPR)</h2>
      <p>
        If you are in the European Economic Area or the United Kingdom, we rely
        on the following legal bases:
      </p>
      <ul>
        <li>
          <strong>Performance of a contract</strong> — to provide the App and
          the features you request, including calculating your charts.
        </li>
        <li>
          <strong>Consent</strong> — for optional processing such as push
          notifications and, where required, sensitive personal data you choose
          to provide. You can withdraw consent at any time.
        </li>
        <li>
          <strong>Legitimate interests</strong> — to keep the Service secure,
          understand how it is used, and improve it, in a way that does not
          override your rights.
        </li>
        <li>
          <strong>Legal obligation</strong> — where we must retain or disclose
          information to comply with the law.
        </li>
      </ul>

      <h2 id="ai">4. AI-generated content and your conversations</h2>
      <p>
        Lively&rsquo;s AI astrologer and reading generation are powered by{" "}
        <strong>OpenAI</strong>. When you chat with the AI or request a
        generated reading, the relevant content — for example your message and
        the astrological context needed to answer it — is sent to OpenAI&rsquo;s
        API to produce a response. We instruct OpenAI to process this data only
        to return a result to you, and under OpenAI&rsquo;s API terms this data
        is not used to train their models.
      </p>
      <p>
        Because AI output is generated automatically, please avoid sharing
        information you would not want processed by a third-party AI service,
        and remember that all AI content is for entertainment and
        self-reflection only (see our{" "}
        <a href="/terms">Terms of Service</a>).
      </p>

      <h2 id="processors">5. Third-party service providers</h2>
      <p>
        We use a small number of trusted providers (&ldquo;processors&rdquo;)
        who process data on our behalf under data-processing agreements. We
        share only what each provider needs to perform its function:
      </p>
      <ul>
        <li>
          <strong>OpenAI</strong> — powers the AI astrologer chat and generated
          readings.
        </li>
        <li>
          <strong>Stripe and/or RevenueCat</strong> — process payments and
          manage subscription entitlements and receipts.
        </li>
        <li>
          <strong>Firebase (Google)</strong> — provides authentication, push
          messaging, and crash reporting / analytics.
        </li>
        <li>
          <strong>Cloud hosting providers</strong> — host the App&rsquo;s
          backend and this website.
        </li>
        <li>
          <strong>Apple App Store and Google Play</strong> — distribute the App
          and process in-app purchases and subscriptions.
        </li>
      </ul>
      <p>
        These providers may process data in accordance with their own privacy
        policies. We keep this list current as our infrastructure evolves.
      </p>

      <h2 id="no-sale">6. We do not sell your data</h2>
      <p>
        <strong>
          We do not sell your personal information, and we do not share it with
          advertisers or data brokers.
        </strong>{" "}
        We do not use your birth details, journal entries, or AI conversations
        for advertising. We disclose information only to the processors listed
        above, when you ask us to, or when we are legally required to do so.
      </p>

      <h2 id="transfers">7. International data transfers</h2>
      <p>
        Some of our providers are located outside your country, including in the
        United States. Where we transfer personal data internationally, we rely
        on appropriate safeguards such as the European Commission&rsquo;s
        Standard Contractual Clauses, or an equivalent lawful transfer
        mechanism, to protect your information.
      </p>

      <h2 id="retention">8. Data retention</h2>
      <p>
        We keep your personal data only for as long as your account is active or
        as needed to provide the Service. Journal entries, birth details, and
        chat history remain available to you until you delete them or delete
        your account. When you delete your account, we delete or irreversibly
        anonymize your personal data within <strong>30 days</strong>, except
        where we are legally required to retain certain records (for example,
        transaction records for tax and accounting), which we keep only for the
        period required by law.
      </p>

      <h2 id="your-rights">9. Your privacy rights</h2>
      <p>
        Depending on where you live, you have some or all of the following
        rights over your personal data:
      </p>
      <ul>
        <li><strong>Access</strong> — obtain a copy of the data we hold about you.</li>
        <li><strong>Rectification</strong> — correct inaccurate or incomplete data.</li>
        <li><strong>Erasure</strong> — delete your account and personal data (&ldquo;right to be forgotten&rdquo;).</li>
        <li><strong>Portability</strong> — receive your data in a portable, machine-readable format.</li>
        <li><strong>Restriction and objection</strong> — limit or object to certain processing.</li>
        <li><strong>Withdraw consent</strong> — where processing is based on consent.</li>
        <li><strong>Complain</strong> — lodge a complaint with your local data protection authority.</li>
      </ul>
      <p>
        You can exercise most of these rights directly in the App
        (Settings &rarr; Account), or by emailing{" "}
        <a href="mailto:hello@livelyapp.co">hello@livelyapp.co</a>. We will
        respond within the timeframe required by applicable law (generally
        within 30 days). We will never charge you for a reasonable request or
        discriminate against you for exercising your rights.
      </p>

      <h2 id="deletion">10. Account deletion and data export</h2>
      <p>
        You can request a full <strong>export</strong> of your data or{" "}
        <strong>delete your account</strong> at any time from{" "}
        <em>Settings &rarr; Account</em> in the App, or by emailing{" "}
        <a href="mailto:hello@livelyapp.co">hello@livelyapp.co</a> from the
        address associated with your account. Deleting your account removes your
        personal data from our systems within 30 days, as described in Section 8.
        See our <a href="/support#delete">Support page</a> for step-by-step
        instructions.
      </p>

      <h2 id="security">11. Security</h2>
      <p>
        We use technical and organizational measures — including encryption in
        transit, access controls, and reputable infrastructure providers — to
        protect your information. No method of transmission or storage is 100%
        secure, but we work hard to safeguard your data and will notify you and
        the relevant authorities of a breach where the law requires it.
      </p>

      <h2 id="children">12. Children</h2>
      <p>
        Lively is intended for adults. The Service is <strong>not directed to
        anyone under 18</strong>, and we do not knowingly collect personal data
        from children. If you believe a minor has provided us with personal
        data, please contact us and we will delete it.
      </p>

      <h2 id="cookies">13. Cookies and the website</h2>
      <p>
        The <strong>website</strong> at livelyapp.co uses only essential
        technologies needed to serve pages and load fonts, and any privacy-
        respecting analytics we may enable to understand aggregate traffic. We
        do not use advertising or cross-site tracking cookies. The{" "}
        <strong>mobile app</strong> does not use advertising cookies; it relies
        on the analytics and diagnostic tools described above. You can control
        cookies through your browser settings. Where required, we will ask for
        your consent before setting non-essential cookies on the website.
      </p>

      <h2 id="changes">14. Changes to this policy</h2>
      <p>
        We may update this Privacy Policy from time to time. When we make
        material changes, we will update the &ldquo;Last updated&rdquo; date
        above and, where appropriate, notify you in the App. Your continued use
        of the Service after an update means you accept the revised policy.
      </p>

      <h2 id="contact">15. Contact us</h2>
      <p>
        For any privacy question or request, contact us at{" "}
        <a href="mailto:hello@livelyapp.co">hello@livelyapp.co</a>. Our legal
        entity is <strong>[Company Legal Entity]</strong>, and our data
        protection point of contact can be reached at the same address.
      </p>
    </PageShell>
  );
}
