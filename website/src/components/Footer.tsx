"use client";

import Image from "next/image";

const groups = [
  {
    title: "Product",
    links: [
      { label: "Features", href: "#features" },
      { label: "Charts", href: "#charts" },
      { label: "AI Astrologer", href: "#ai" },
      { label: "Community", href: "#community" },
      { label: "Pricing", href: "#pricing" },
    ],
  },
  {
    title: "Company",
    links: [
      { label: "About", href: "#" },
      { label: "Blog", href: "#" },
      { label: "Press", href: "#" },
      { label: "Contact", href: "mailto:hello@livelyapp.co" },
    ],
  },
  {
    title: "Legal",
    links: [
      { label: "Privacy", href: "#" },
      { label: "Terms", href: "#" },
      { label: "Cookies", href: "#" },
    ],
  },
];

export function Footer() {
  return (
    <footer className="relative border-t border-white/5 bg-black/30 pt-16">
      <div className="mx-auto grid max-w-7xl gap-10 px-5 pb-10 md:grid-cols-5 md:px-8">
        <div className="md:col-span-2">
          <div className="flex items-center">
            <Image
              src="/lively_logo.png"
              alt="Lively"
              width={64}
              height={64}
              className="h-16 w-16 drop-shadow-[0_0_18px_rgba(212,177,106,0.4)]"
            />
          </div>
          <p className="mt-4 max-w-sm text-sm text-cosmic-muted">
            A complete spiritual toolkit — Western, Vedic, numerology, Human
            Design, and a personal AI astrologer that knows your sky.
          </p>
          <div className="mt-5 flex gap-3">
            {[
              ["Instagram", "M12 2.2c3.2 0 3.6 0 4.8.1 1.2 0 1.9.2 2.4.4.6.2 1 .5 1.5 1s.8.9 1 1.5c.2.5.3 1.2.4 2.4.1 1.2.1 1.6.1 4.8s0 3.6-.1 4.8c0 1.2-.2 1.9-.4 2.4-.2.6-.5 1-1 1.5s-.9.8-1.5 1c-.5.2-1.2.3-2.4.4-1.2.1-1.6.1-4.8.1s-3.6 0-4.8-.1c-1.2 0-1.9-.2-2.4-.4-.6-.2-1-.5-1.5-1s-.8-.9-1-1.5c-.2-.5-.3-1.2-.4-2.4-.1-1.2-.1-1.6-.1-4.8s0-3.6.1-4.8c0-1.2.2-1.9.4-2.4.2-.6.5-1 1-1.5s.9-.8 1.5-1c.5-.2 1.2-.3 2.4-.4C8.4 2.2 8.8 2.2 12 2.2zm0 1.8c-3.1 0-3.5 0-4.7.1-1 0-1.6.2-2 .3-.5.2-.8.4-1.2.7s-.6.7-.7 1.2c-.1.4-.3 1-.3 2-.1 1.2-.1 1.6-.1 4.7s0 3.5.1 4.7c0 1 .2 1.6.3 2 .2.5.4.8.7 1.2s.7.6 1.2.7c.4.1 1 .3 2 .3 1.2.1 1.6.1 4.7.1s3.5 0 4.7-.1c1 0 1.6-.2 2-.3.5-.2.8-.4 1.2-.7s.6-.7.7-1.2c.1-.4.3-1 .3-2 .1-1.2.1-1.6.1-4.7s0-3.5-.1-4.7c0-1-.2-1.6-.3-2-.2-.5-.4-.8-.7-1.2s-.7-.6-1.2-.7c-.4-.1-1-.3-2-.3-1.2-.1-1.6-.1-4.7-.1zm0 3.1c2.7 0 4.9 2.2 4.9 4.9s-2.2 4.9-4.9 4.9-4.9-2.2-4.9-4.9 2.2-4.9 4.9-4.9zm0 8.1c1.8 0 3.2-1.4 3.2-3.2S13.8 8.8 12 8.8s-3.2 1.4-3.2 3.2 1.4 3.2 3.2 3.2zm6.4-8.3c0 .6-.5 1.1-1.1 1.1s-1.1-.5-1.1-1.1.5-1.1 1.1-1.1 1.1.5 1.1 1.1z"],
              ["X", "M18.244 2H21l-6.55 7.49L22 22h-6.83l-4.84-6.36L4.6 22H2l7.16-8.18L1.5 2h7l4.36 5.86L18.244 2zm-2.4 18.24h1.58L7.65 3.66H5.96l9.884 16.58z"],
              ["Email", "M2 6.5A2.5 2.5 0 0 1 4.5 4h15A2.5 2.5 0 0 1 22 6.5v11A2.5 2.5 0 0 1 19.5 20h-15A2.5 2.5 0 0 1 2 17.5v-11zm2.5-.5a.5.5 0 0 0-.5.5v.34l8 5 8-5V6.5a.5.5 0 0 0-.5-.5h-15zM20 9.16l-7.45 4.66a1 1 0 0 1-1.1 0L4 9.16V17.5a.5.5 0 0 0 .5.5h15a.5.5 0 0 0 .5-.5V9.16z"],
            ].map(([label, path]) => (
              <a
                key={label}
                href="#"
                aria-label={label}
                className="grid h-9 w-9 place-items-center rounded-full border border-white/10 bg-white/5 text-cosmic-muted transition-colors hover:border-gold/40 hover:text-gold"
              >
                <svg viewBox="0 0 24 24" className="h-4 w-4" fill="currentColor">
                  <path d={path} />
                </svg>
              </a>
            ))}
          </div>
        </div>
        {groups.map((g) => (
          <div key={g.title}>
            <div className="text-xs font-bold uppercase tracking-wider text-gold">
              {g.title}
            </div>
            <ul className="mt-4 space-y-2">
              {g.links.map((l) => (
                <li key={l.label}>
                  <a
                    href={l.href}
                    className="text-sm text-cosmic-muted transition-colors hover:text-cosmic-text"
                  >
                    {l.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>
      <div className="border-t border-white/5">
        <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-3 px-5 py-6 text-xs text-cosmic-dim md:flex-row md:px-8">
          <span>© {new Date().getFullYear()} Lively. Made under the stars.</span>
          <span>For entertainment + self-reflection — not a substitute for professional advice.</span>
        </div>
      </div>
    </footer>
  );
}
