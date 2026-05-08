"use client";

import { motion } from "framer-motion";
import Image from "next/image";
import { PhoneMock } from "./PhoneMock";

export function Hero() {
  return (
    <section className="relative isolate overflow-hidden pt-32 md:pt-40">
      {/* Soft top spotlight */}
      <div className="pointer-events-none absolute -top-32 left-1/2 h-96 w-[60rem] -translate-x-1/2 rounded-full bg-gold/10 blur-3xl" />
      <div className="mx-auto grid max-w-7xl items-center gap-12 px-5 md:grid-cols-2 md:gap-8 md:px-8">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: "easeOut" }}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.85 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.9, delay: 0.05, ease: "easeOut" }}
            className="mb-6"
          >
            <Image
              src="/lively_logo.png"
              alt="Lively"
              width={128}
              height={128}
              priority
              className="h-28 w-28 drop-shadow-[0_0_40px_rgba(212,177,106,0.55)] animate-floaty md:h-32 md:w-32"
            />
          </motion.div>
          <span className="inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-3 py-1 text-xs font-semibold tracking-wide text-gold">
            <span className="h-1.5 w-1.5 rounded-full bg-gold animate-twinkle" />
            Astrology · Numerology · Human Design
          </span>
          <h1 className="mt-5 font-display text-5xl font-black leading-[1.05] tracking-tight md:text-7xl">
            Your <span className="text-gold-gradient">cosmic</span>
            <br />
            blueprint, in one app.
          </h1>
          <p className="mt-6 max-w-xl text-lg leading-relaxed text-cosmic-muted md:text-xl">
            Lively is a complete spiritual toolkit — a precise natal chart,
            full Vedic kundli, Pythagorean numerology, your Human Design
            body graph, and a personal AI astrologer that knows your sky.
          </p>
          <div className="mt-9 flex flex-wrap items-center gap-3">
            <StoreButton
              storeName="App Store"
              tagline="Download on the"
              href="#download"
              icon={
                <svg
                  viewBox="0 0 24 24"
                  className="h-7 w-7"
                  fill="currentColor"
                >
                  <path d="M16.365 1.43c0 1.14-.46 2.235-1.21 3.045-.81.87-2.13 1.545-3.18 1.46-.135-1.11.42-2.265 1.155-3.045.81-.87 2.205-1.515 3.235-1.46zM20.55 17.34c-.42.96-.62 1.395-1.16 2.235-.755 1.17-1.815 2.625-3.135 2.64-1.17.015-1.47-.765-3.06-.75-1.59.015-1.92.765-3.09.75-1.32-.015-2.325-1.32-3.075-2.49-2.1-3.255-2.325-7.08-1.025-9.105.92-1.44 2.385-2.295 3.755-2.295 1.395 0 2.265.78 3.42.78 1.125 0 1.815-.78 3.435-.78 1.215 0 2.505.66 3.435 1.785-3.015 1.65-2.535 5.97.5 7.23z" />
                </svg>
              }
            />
            <StoreButton
              storeName="Google Play"
              tagline="Get it on"
              href="#download"
              icon={
                <svg
                  viewBox="0 0 24 24"
                  className="h-7 w-7"
                  fill="currentColor"
                >
                  <path d="M3.609 1.814L13.792 12 3.61 22.186a.996.996 0 0 1-.61-.92V2.734a1 1 0 0 1 .609-.92zm10.89 10.893l2.302 2.302-10.937 6.323 8.635-8.625zM6.001 1.65l10.928 6.32-2.32 2.32L5.998 1.65zm14.79 8.32c.69.396.69 1.385 0 1.78l-2.434 1.405-2.539-2.295 2.539-2.295 2.434 1.405z" />
                </svg>
              }
            />
            <a
              href="#features"
              className="inline-flex items-center gap-2 rounded-full border border-white/10 px-5 py-3 text-sm font-semibold text-cosmic-muted transition-colors hover:border-gold/50 hover:text-cosmic-text"
            >
              See features <span aria-hidden>→</span>
            </a>
          </div>
          <div className="mt-8 flex items-center gap-5 text-xs text-cosmic-dim">
            <Stars />
            <span>4.9 average · 12,000+ readings cast</span>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.9, y: 30 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          transition={{ duration: 1, delay: 0.15, ease: "easeOut" }}
          className="relative mx-auto"
        >
          <PhoneMock />
        </motion.div>
      </div>
    </section>
  );
}

function StoreButton({
  storeName,
  tagline,
  href,
  icon,
}: {
  storeName: string;
  tagline: string;
  href: string;
  icon: React.ReactNode;
}) {
  return (
    <a
      href={href}
      className="group inline-flex items-center gap-3 rounded-2xl border border-white/15 bg-white/5 px-4 py-3 transition-all hover:border-gold/40 hover:bg-white/10"
    >
      <span className="text-cosmic-text">{icon}</span>
      <span className="flex flex-col text-left leading-tight">
        <span className="text-[10px] uppercase tracking-wider text-cosmic-muted">
          {tagline}
        </span>
        <span className="font-display text-base font-bold text-cosmic-text">
          {storeName}
        </span>
      </span>
    </a>
  );
}

function Stars() {
  return (
    <div className="flex">
      {[0, 1, 2, 3, 4].map((i) => (
        <svg
          key={i}
          viewBox="0 0 24 24"
          className="h-4 w-4 fill-gold"
          aria-hidden
        >
          <path d="M12 2l2.9 6.9 7.1.6-5.4 4.6 1.6 7.1L12 17.3 5.8 21.2l1.6-7.1L2 9.5l7.1-.6L12 2z" />
        </svg>
      ))}
    </div>
  );
}
