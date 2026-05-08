"use client";

import { motion } from "framer-motion";

export function DownloadCTA() {
  return (
    <section id="download" className="section-y relative">
      <div className="mx-auto max-w-5xl px-5 md:px-8">
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          whileInView={{ opacity: 1, scale: 1 }}
          viewport={{ once: true, amount: 0.3 }}
          transition={{ duration: 0.7, ease: "easeOut" }}
          className="relative overflow-hidden rounded-[2.5rem] border border-gold/30 bg-gradient-to-br from-gold/10 via-cosmic-bg to-cosmic-bg p-10 text-center md:p-16"
        >
          {/* Decorative spotlights */}
          <div className="pointer-events-none absolute -left-20 -top-20 h-80 w-80 rounded-full bg-gold/15 blur-3xl" />
          <div className="pointer-events-none absolute -bottom-20 -right-20 h-80 w-80 rounded-full bg-gold/15 blur-3xl" />

          <div className="relative">
            <h2 className="font-display text-4xl font-black leading-tight md:text-6xl">
              Your sky is waiting.
            </h2>
            <p className="mx-auto mt-5 max-w-xl text-lg text-cosmic-muted">
              Download Lively and meet a version of yourself written in the
              stars — and the numbers, and the centers.
            </p>

            <div className="mt-9 flex flex-wrap items-center justify-center gap-3">
              <Pill
                store="App Store"
                tagline="Download on the"
                icon={
                  <svg viewBox="0 0 24 24" className="h-7 w-7" fill="currentColor">
                    <path d="M16.365 1.43c0 1.14-.46 2.235-1.21 3.045-.81.87-2.13 1.545-3.18 1.46-.135-1.11.42-2.265 1.155-3.045.81-.87 2.205-1.515 3.235-1.46zM20.55 17.34c-.42.96-.62 1.395-1.16 2.235-.755 1.17-1.815 2.625-3.135 2.64-1.17.015-1.47-.765-3.06-.75-1.59.015-1.92.765-3.09.75-1.32-.015-2.325-1.32-3.075-2.49-2.1-3.255-2.325-7.08-1.025-9.105.92-1.44 2.385-2.295 3.755-2.295 1.395 0 2.265.78 3.42.78 1.125 0 1.815-.78 3.435-.78 1.215 0 2.505.66 3.435 1.785-3.015 1.65-2.535 5.97.5 7.23z" />
                  </svg>
                }
              />
              <Pill
                store="Google Play"
                tagline="Get it on"
                icon={
                  <svg viewBox="0 0 24 24" className="h-7 w-7" fill="currentColor">
                    <path d="M3.609 1.814L13.792 12 3.61 22.186a.996.996 0 0 1-.61-.92V2.734a1 1 0 0 1 .609-.92zm10.89 10.893l2.302 2.302-10.937 6.323 8.635-8.625zM6.001 1.65l10.928 6.32-2.32 2.32L5.998 1.65zm14.79 8.32c.69.396.69 1.385 0 1.78l-2.434 1.405-2.539-2.295 2.539-2.295 2.434 1.405z" />
                  </svg>
                }
              />
            </div>

            <div className="mt-6 text-xs text-cosmic-dim">
              Free to download · iOS 14+ · Android 8+
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}

function Pill({
  store,
  tagline,
  icon,
}: {
  store: string;
  tagline: string;
  icon: React.ReactNode;
}) {
  return (
    <a
      href="#"
      className="group inline-flex items-center gap-3 rounded-2xl border border-white/15 bg-cosmic-bg/60 px-5 py-3 transition-all hover:border-gold/40 hover:bg-cosmic-bg"
    >
      <span className="text-cosmic-text">{icon}</span>
      <span className="flex flex-col text-left leading-tight">
        <span className="text-[10px] uppercase tracking-wider text-cosmic-muted">
          {tagline}
        </span>
        <span className="font-display text-base font-bold text-cosmic-text">
          {store}
        </span>
      </span>
    </a>
  );
}
