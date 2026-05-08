import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Lively — Your Cosmic Blueprint",
  description:
    "Western, Vedic, Numerology, and Human Design — all in one app. Daily readings, an AI astrologer, compatibility, journaling, and a community of fellow seekers.",
  keywords: [
    "astrology",
    "vedic astrology",
    "numerology",
    "human design",
    "natal chart",
    "compatibility",
    "AI astrologer",
    "Lively app",
  ],
  openGraph: {
    title: "Lively — Your Cosmic Blueprint",
    description:
      "Western, Vedic, Numerology, and Human Design — all in one app.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        {/* Self-hosted Google fonts — pulled at request time so Tailwind
            font-display + font-sans pick them up without a build step. */}
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link
          rel="preconnect"
          href="https://fonts.gstatic.com"
          crossOrigin=""
        />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Poppins:wght@500;600;700;800;900&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="font-sans">{children}</body>
    </html>
  );
}
