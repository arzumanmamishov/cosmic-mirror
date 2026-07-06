package handler

// Legal copy served by GET /legal/privacy and GET /legal/terms. This is the
// source of truth the mobile app renders in-app; the marketing site mirrors it
// at livelyapp.co/privacy and /terms.
//
// TEMPLATE NOTICE: This is a good-faith, tailored draft — NOT a substitute for
// review by qualified legal counsel. Before production launch, have counsel
// review it and replace the bracketed placeholders ([Company Legal Entity],
// [Jurisdiction]). Bump legalVersion + legalEffectiveDate on any material
// change so clients can re-prompt for consent.

const (
	legalVersion       = "1.0"
	legalEffectiveDate = "2026-07-06"
)

const privacyPolicyText = `PRIVACY POLICY — Lively
Effective: 6 July 2026 · Version 1.0

Lively ("Lively", "we", "us"), operated by [Company Legal Entity], provides an
astrology and self-guidance mobile application. This policy explains what we
collect, why, and the choices you have. Questions: privacy@livelyapp.co.

1. DATA WE COLLECT
• Account data: email address and (optionally) your name.
• Birth data: your birth date, birth time (optional), and birth place
  (city plus its coordinates and timezone). We use this solely to compute your
  astrological chart and personalize content.
• Content you create: journal entries, saved people you add for compatibility,
  chat messages to the AI astrologer, and ritual/streak activity.
• Subscription data: your plan and entitlement status (billing itself is
  handled by the app stores and our payment processors — we never receive your
  full card number).
• Technical & usage data: device type, app version, language, crash diagnostics,
  and aggregate feature-usage analytics.

2. HOW WE USE IT
To create and secure your account; calculate your chart and generate readings,
forecasts, compatibility reports and chat responses; operate rituals, journaling
and notifications you enable; provide support; and improve reliability and
content quality. We do not use your journal entries or chat messages to train
third-party AI models.

3. THIRD-PARTY PROCESSORS
We share the minimum data necessary with vendors who process it on our behalf:
• OpenAI — generates AI readings, forecasts, and chat replies. Relevant birth
  data and your message text are sent to produce a response.
• Stripe and/or RevenueCat — process and validate subscription payments.
• Firebase (Google) — authentication support, push notifications, and crash
  reporting.
• Cloud hosting and email delivery providers.
These vendors are contractually bound to protect your data and use it only to
provide their service to us. We do NOT sell your personal data.

4. DATA RETENTION
We keep your data while your account is active. When you delete your account,
we remove your personal data from our production systems within 30 days
(backups roll off on their normal cycle). Some records may be retained where
required by law (e.g. tax/payment records).

5. YOUR RIGHTS (INCLUDING GDPR)
Subject to applicable law, you may access, correct, export, or delete your data,
and object to or restrict certain processing. You can delete your account and
all associated personal data from within the app (Settings → Delete Account),
or email privacy@livelyapp.co. EU/EEA/UK users may lodge a complaint with their
local supervisory authority.

6. SECURITY
We use encryption in transit, access controls, and reputable infrastructure
providers. No system is perfectly secure, but we work to protect your data.

7. CHILDREN
Lively is intended for users aged 18 and older. We do not knowingly collect data
from anyone under 18.

8. INTERNATIONAL TRANSFERS
Your data may be processed in countries other than your own, including the
United States, under appropriate safeguards (such as Standard Contractual
Clauses) where required.

9. CHANGES
We may update this policy; we will revise the version and effective date above
and, for material changes, notify you in the app.

10. CONTACT
[Company Legal Entity] · privacy@livelyapp.co · https://livelyapp.co/privacy

Astrology content in Lively is provided for entertainment and self-reflection
and is not professional advice. See our Terms of Service.`

const termsOfServiceText = `TERMS OF SERVICE — Lively
Effective: 6 July 2026 · Version 1.0

These Terms are a legal agreement between you and [Company Legal Entity]
("Lively", "we", "us") governing your use of the Lively app. By creating an
account or using the app, you agree to these Terms.

1. ELIGIBILITY
You must be at least 18 years old and able to form a binding contract.

2. YOUR ACCOUNT
You are responsible for your login credentials and for activity under your
account. Provide accurate information and keep it up to date.

3. ENTERTAINMENT & NO PROFESSIONAL ADVICE (IMPORTANT)
Lively provides astrology, numerology, and AI-generated content for
entertainment and self-reflection only. It is NOT professional medical,
psychological, legal, financial, or other advice, and must not be relied on as
such. Always consult a qualified professional for those matters. The AI
astrologer will decline medical, legal, or financial requests and direct you to
a professional. You are solely responsible for decisions you make.

4. SUBSCRIPTIONS & BILLING
Lively offers auto-renewing subscriptions (for example, a monthly plan and a
discounted yearly plan; the yearly plan may include a 3-day free trial). Exact
prices and any trial are shown in the app before you purchase.
• Payment is charged to your Apple App Store or Google Play account at
  confirmation of purchase.
• Subscriptions renew automatically unless cancelled at least 24 hours before
  the end of the current period. Manage or cancel anytime in your App Store /
  Google Play account settings.
• If a trial is offered, any unused portion is forfeited when you purchase a
  subscription, where applicable.
• Restore Purchases is available on the paywall and in Settings.
Refunds are handled by the applicable app store under its policies.

5. ACCEPTABLE USE
Do not misuse the app: no unlawful, harmful, harassing, or infringing activity;
no attempts to break security, scrape, reverse engineer, or disrupt the service;
no automated abuse of the AI features.

6. USER CONTENT
You retain ownership of content you create (journal entries, messages, saved
people). You grant us a limited licence to process it solely to provide the
service to you, as described in the Privacy Policy.

7. INTELLECTUAL PROPERTY
The app, its design, and generated content templates are owned by us or our
licensors and are protected by law. We grant you a personal, non-transferable,
revocable licence to use the app.

8. DISCLAIMERS
The app is provided "as is" and "as available" without warranties of any kind
to the fullest extent permitted by law. We do not warrant that content is
accurate or that the service will be uninterrupted or error-free.

9. LIMITATION OF LIABILITY
To the maximum extent permitted by law, we are not liable for indirect,
incidental, special, consequential, or punitive damages, or for any loss
arising from your reliance on astrology or AI content. Nothing limits liability
that cannot be limited by law.

10. TERMINATION
You may stop using the app and delete your account at any time. We may suspend
or terminate access for breach of these Terms or to comply with law.

11. GOVERNING LAW
These Terms are governed by the laws of [Jurisdiction], without regard to its
conflict-of-laws rules, subject to any mandatory consumer protections in your
country of residence.

12. CHANGES
We may update these Terms; we will revise the version and effective date above
and, for material changes, notify you in the app. Continued use means you accept
the updated Terms.

13. CONTACT
[Company Legal Entity] · support@livelyapp.co · https://livelyapp.co/terms`
