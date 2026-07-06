/* <!-- TEMPLATE: review by legal counsel before production launch. Placeholders: governing-law jurisdiction, company legal entity name. --> */
import type { Metadata } from "next";
import { PageShell } from "@/components/PageShell";

export const metadata: Metadata = {
  title: "Terms of Service — Lively",
  description:
    "The terms that govern your use of Lively — including subscriptions, acceptable use, and the important reminder that astrology and AI content is for entertainment and self-reflection only.",
  alternates: { canonical: "/terms" },
  openGraph: {
    title: "Terms of Service — Lively",
    description: "The terms that govern your use of the Lively app.",
    type: "website",
  },
};

const LAST_UPDATED = "6 July 2026";

export default function TermsPage() {
  return (
    <PageShell
      eyebrow="Legal"
      title={
        <>
          Terms of <span className="text-gold-gradient">Service</span>
        </>
      }
      lastUpdated={LAST_UPDATED}
      intro="These terms are the agreement between you and Lively. Please read them carefully — they include an important note about the entertainment nature of astrology and AI content, and how subscriptions work."
    >
      <p>
        These Terms of Service (the &ldquo;Terms&rdquo;) govern your use of the
        Lively mobile application and the website at{" "}
        <a href="https://livelyapp.co">livelyapp.co</a> (together, the
        &ldquo;Service&rdquo;), provided by{" "}
        <strong>[Company Legal Entity]</strong> (&ldquo;Lively,&rdquo;
        &ldquo;we,&rdquo; &ldquo;us,&rdquo; or &ldquo;our&rdquo;). By
        downloading, accessing, or using the Service, you agree to be bound by
        these Terms. If you do not agree, please do not use the Service.
      </p>

      <h2 id="acceptance">1. Acceptance of these terms</h2>
      <p>
        By creating an account or using the Service, you confirm that you have
        read, understood, and agree to these Terms and to our{" "}
        <a href="/privacy">Privacy Policy</a>, which is incorporated by
        reference. If you are using the Service on behalf of someone else, you
        confirm you are authorized to accept these Terms on their behalf.
      </p>

      <h2 id="eligibility">2. Eligibility</h2>
      <p>
        You must be at least <strong>18 years old</strong> to use Lively. By
        using the Service you represent and warrant that you are 18 or older and
        legally able to enter into this agreement. The Service is not intended
        for and may not be used by anyone under 18.
      </p>

      <h2 id="account">3. Your account</h2>
      <ul>
        <li>You are responsible for the accuracy of the information you provide, including your birth details.</li>
        <li>You are responsible for keeping your login credentials confidential and for all activity under your account.</li>
        <li>You agree to notify us promptly at <a href="mailto:hello@livelyapp.co">hello@livelyapp.co</a> of any unauthorized use of your account.</li>
        <li>You may not share your account or transfer it to anyone else.</li>
      </ul>

      <h2 id="service">4. The Service</h2>
      <p>
        Lively provides astrology tools (Western, Vedic, numerology, and Human
        Design), personalized readings, an AI astrologer, compatibility
        reports, journaling, rituals, and a community. We may add, change, or
        remove features over time to improve the Service.
      </p>

      <h2 id="subscriptions">5. Subscriptions, trials, and payments</h2>
      <p>
        Lively offers a free tier and an optional <strong>Premium</strong>
        subscription that unlocks advanced features.
      </p>
      <ul>
        <li>
          <strong>Pricing.</strong> Premium is offered as a monthly plan
          (approximately <strong>&euro;6.99/month</strong>) or an annual plan
          (approximately <strong>&euro;39.99/year</strong>). Exact prices are
          shown in the App at the point of purchase and may vary by region,
          currency, and applicable taxes.
        </li>
        <li>
          <strong>Free trial.</strong> The annual plan may include a{" "}
          <strong>3-day free trial</strong>. If you do not cancel before the
          trial ends, the subscription automatically converts to a paid annual
          subscription and you will be charged.
        </li>
        <li>
          <strong>Auto-renewal.</strong> Subscriptions renew automatically at
          the end of each billing period unless you cancel at least 24 hours
          before the period ends. Your account will be charged for renewal
          within 24 hours prior to the end of the current period.
        </li>
        <li>
          <strong>Billing.</strong> Purchases are processed by the{" "}
          <strong>Apple App Store</strong> or <strong>Google Play</strong>
          (and, where applicable, our payment processors Stripe and/or
          RevenueCat). Payment is charged to your app store account.
        </li>
        <li>
          <strong>Cancel anytime.</strong> You can cancel at any time in your{" "}
          Apple App Store or Google Play account settings. Cancellation stops
          future renewals; you keep Premium access until the end of the paid
          period. Deleting the App does not cancel your subscription.
        </li>
        <li>
          <strong>Restore purchases.</strong> If you reinstall the App or switch
          devices (on the same store account), you can restore an active
          subscription using the &ldquo;Restore Purchases&rdquo; option in the
          App.
        </li>
        <li>
          <strong>Refunds.</strong> Refunds are handled by the app store
          according to its policies, not directly by Lively. Except where
          required by law, subscription fees are non-refundable.
        </li>
        <li>
          <strong>Price changes.</strong> We may change subscription prices.
          Any change applies to future billing periods and, where required by
          law or app store rules, we will give you advance notice and the
          opportunity to cancel.
        </li>
      </ul>

      <h2 id="entertainment">6. Entertainment disclaimer — please read</h2>
      <div className="legal-callout">
        <p>
          <strong>
            Lively is provided for entertainment and self-reflection only.
          </strong>{" "}
          Astrology, numerology, Human Design, and all AI-generated content are
          not scientifically proven and are <strong>not</strong> a substitute
          for professional advice.
        </p>
        <p>
          Nothing in the Service constitutes medical, psychological,
          psychiatric, legal, financial, or other professional advice, and you
          should not rely on it as such. Always seek the guidance of a qualified
          professional for decisions affecting your health, finances, legal
          situation, relationships, or wellbeing.
        </p>
        <p>
          The AI astrologer is designed to <strong>decline and redirect</strong>{" "}
          requests for medical, legal, financial, or crisis advice to
          appropriate professionals. <strong>
            If you are experiencing a medical or mental-health emergency, contact
            your local emergency services or a crisis helpline immediately.
          </strong>
        </p>
      </div>
      <p>
        By using the Service, you acknowledge that you understand its
        entertainment purpose and that you are solely responsible for any
        decisions you make based on it.
      </p>

      <h2 id="acceptable-use">7. Acceptable use</h2>
      <p>You agree not to:</p>
      <ul>
        <li>Use the Service for any unlawful, harmful, or fraudulent purpose.</li>
        <li>Harass, abuse, threaten, or harm other users, including in the community features.</li>
        <li>Post content that is illegal, hateful, defamatory, sexually explicit involving minors, or that violates others&rsquo; rights.</li>
        <li>Attempt to reverse-engineer, decompile, scrape, or gain unauthorized access to the Service or its systems.</li>
        <li>Interfere with or disrupt the Service, or circumvent security or subscription controls.</li>
        <li>Impersonate any person or misrepresent your affiliation.</li>
        <li>Use automated means to access the Service except as expressly permitted.</li>
      </ul>
      <p>
        We may remove content or suspend accounts that violate these rules.
      </p>

      <h2 id="user-content">8. Your content</h2>
      <p>
        You retain ownership of the content you create in the App, such as
        journal entries, community posts, and messages (&ldquo;User
        Content&rdquo;). You grant us a limited, worldwide, non-exclusive,
        royalty-free license to host, store, process, and display your User
        Content solely to operate and provide the Service to you (for example,
        sending an AI chat message to our AI provider to generate a reply). You
        are responsible for your User Content and confirm you have the rights to
        share it.
      </p>

      <h2 id="ip">9. Intellectual property</h2>
      <p>
        The Service, including its software, design, text, graphics, logos, and
        the &ldquo;Lively&rdquo; name, is owned by us or our licensors and
        protected by intellectual-property laws. We grant you a personal,
        limited, non-transferable, revocable license to use the Service for your
        own non-commercial use, subject to these Terms. You may not copy,
        modify, distribute, sell, or lease any part of the Service.
      </p>

      <h2 id="third-party">10. Third-party services</h2>
      <p>
        The Service relies on third parties such as the Apple App Store, Google
        Play, OpenAI, Stripe/RevenueCat, and Firebase. Your use of those
        services may be subject to their own terms. We are not responsible for
        third-party services, and any app store (including Apple) is a third-
        party beneficiary of these Terms and may enforce them against you.
      </p>

      <h2 id="warranty">11. Disclaimer of warranties</h2>
      <p>
        The Service is provided <strong>&ldquo;as is&rdquo;</strong> and{" "}
        <strong>&ldquo;as available,&rdquo;</strong> without warranties of any
        kind, whether express or implied, including implied warranties of
        merchantability, fitness for a particular purpose, and non-infringement.
        We do not warrant that the Service will be uninterrupted, error-free, or
        that any content — astrological, AI-generated, or otherwise — is
        accurate, reliable, or complete.
      </p>

      <h2 id="liability">12. Limitation of liability</h2>
      <p>
        To the maximum extent permitted by law, Lively and its affiliates,
        officers, employees, and suppliers will not be liable for any indirect,
        incidental, special, consequential, or punitive damages, or any loss of
        data, profits, or goodwill, arising from your use of, or inability to
        use, the Service. To the extent liability cannot be excluded, our total
        aggregate liability is limited to the greater of the amount you paid us
        in the 12 months before the claim or &euro;50. Nothing in these Terms
        limits liability that cannot be limited under applicable law.
      </p>

      <h2 id="indemnity">13. Indemnification</h2>
      <p>
        You agree to indemnify and hold harmless Lively from any claims,
        damages, or expenses arising out of your misuse of the Service, your
        User Content, or your violation of these Terms or of any law or
        third-party right.
      </p>

      <h2 id="termination">14. Termination</h2>
      <p>
        You may stop using the Service and delete your account at any time. We
        may suspend or terminate your access if you breach these Terms, misuse
        the Service, or where required by law. On termination, your right to use
        the Service ends; sections that by their nature should survive
        (including intellectual property, disclaimers, limitation of liability,
        and governing law) will survive.
      </p>

      <h2 id="changes">15. Changes to these terms</h2>
      <p>
        We may update these Terms from time to time. When we make material
        changes, we will update the &ldquo;Last updated&rdquo; date above and,
        where appropriate, notify you in the App. Your continued use of the
        Service after an update means you accept the revised Terms.
      </p>

      <h2 id="governing-law">16. Governing law and disputes</h2>
      <p>
        These Terms are governed by the laws of <strong>[Jurisdiction]</strong>,
        without regard to its conflict-of-laws rules, and the courts of{" "}
        <strong>[Jurisdiction]</strong> will have jurisdiction over any dispute,
        except where mandatory consumer-protection laws of your country of
        residence provide otherwise. Nothing in this section deprives you of the
        protection of the mandatory consumer laws that apply where you live.
      </p>

      <h2 id="contact">17. Contact us</h2>
      <p>
        Questions about these Terms? Contact us at{" "}
        <a href="mailto:hello@livelyapp.co">hello@livelyapp.co</a>. For help
        using the App, visit our <a href="/support">Support page</a>.
      </p>
    </PageShell>
  );
}
