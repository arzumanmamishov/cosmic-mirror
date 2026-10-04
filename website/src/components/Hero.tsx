"use client";

import {
  AnimatePresence,
  motion,
  useReducedMotion,
  useScroll,
  useTransform,
} from "framer-motion";
import Image from "next/image";
import { useEffect, useState } from "react";
import { Magnetic, RevealWords } from "./fx/Effects";
import { ZodiacWheel } from "./fx/ZodiacWheel";
import { PhoneMock } from "./PhoneMock";

const ROTATING = ["cosmic", "Vedic", "numerology", "Human Design"];

export function Hero() {
  const reduce = useReducedMotion();
  const [word, setWord] = useState(0);
  const { scrollY } = useScroll();
  // Hero content drifts up and fades as you scroll past it.
  const contentY = useTransform(scrollY, [0, 600], [0, -80]);
  const contentO = useTransform(scrollY, [0, 500], [1, 0.2]);
  const phoneY = useTransform(scrollY, [0, 600], [0, 60]);

  useEffect(() => {
    if (reduce) return;
    const id = setInterval(() => setWord((w) => (w + 1) % ROTATING.length), 2400);
    return () => clearInterval(id);
  }, [reduce]);

  return (
    <section className="relative isolate overflow-hidden pt-32 md:min-h-screen md:pt-36">
      {/* Soft top spotlight */}
      <div className="pointer-events-none absolute -top-32 left-1/2 h-96 w-[60rem] -translate-x-1/2 rounded-full bg-gold/10 blur-3xl" />
      <div className="mx-auto grid max-w-7xl items-center gap-12 px-5 md:grid-cols-2 md:gap-8 md:px-8">
        <motion.div style={reduce ? undefined : { y: contentY, opacity: contentO }}>
          <motion.div
            initial={{ opacity: 0, scale: 0.6, rotate: -20 }}
            animate={{ opacity: 1, scale: 1, rotate: 0 }}
            transition={{ duration: 1.1, ease: [0.22, 1, 0.36, 1] }}
            className="mb-6"
          >
            <Image
              src="/lively_logo.png"
              alt="Lively"
              width={128}
              height={128}
              priority
              className="h-24 w-24 drop-shadow-[0_0_40px_rgba(212,177,106,0.55)] animate-floaty md:h-28 md:w-28"
            />
          </motion.div>
          <motion.span
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2, duration: 0.6 }}
            className="inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-3 py-1 text-xs font-semibold tracking-wide text-gold"
          >
            <span className="relative flex h-2 w-2">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-gold opacity-60" />
              <span className="relative inline-flex h-2 w-2 rounded-full bg-gold" />
            </span>
            Astrology · Numerology · Human Design
          </motion.span>
          <h1 className="mt-5 font-display text-5xl font-black leading-[1.05] tracking-tight md:text-6xl xl:text-7xl">
            <RevealWords text="Your" delay={0.25} />
            <br />
            {/* Own line with a fixed height, so swapping in a longer word
                never reflows the headline. */}
            <span className="relative inline-flex h-[1.15em] overflow-hidden align-bottom">
              <AnimatePresence mode="popLayout" initial={false}>
                <motion.span
                  key={ROTATING[word]}
                  initial={{ y: "100%", opacity: 0, filter: "blur(6px)" }}
                  animate={{ y: "0%", opacity: 1, filter: "blur(0px)" }}
                  exit={{ y: "-100%", opacity: 0, filter: "blur(6px)" }}
                  transition={{ duration: 0.55, ease: [0.22, 1, 0.36, 1] }}
                  className="text-gold-gradient text-shimmer whitespace-nowrap"
                >
                  {ROTATING[word]}
                </motion.span>
              </AnimatePresence>
            </span>
            <br />
            <RevealWords text="blueprint, in one app." delay={0.4} />
          </h1>
          <motion.p
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.7, duration: 0.7 }}
            className="mt-6 max-w-xl text-lg leading-relaxed text-cosmic-muted md:text-xl"
          >
            Lively is a complete spiritual toolkit — a precise natal chart,
            full Vedic kundli, Pythagorean numerology, your Human Design
            body graph, and a personal AI astrologer that knows your sky.
          </motion.p>
          <motion.div
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.85, duration: 0.7 }}
            className="mt-9 flex flex-wrap items-center gap-3"
          >
            <Magnetic>
              <StoreButton
                storeName="App Store"
                tagline="Download on the"
                href="#download"
                icon={
                  <svg viewBox="0 0 24 24" className="h-7 w-7" fill="currentColor">
                    <path d="M16.365 1.43c0 1.14-.46 2.235-1.21 3.045-.81.87-2.13 1.545-3.18 1.46-.135-1.11.42-2.265 1.155-3.045.81-.87 2.205-1.515 3.235-1.46zM20.55 17.34c-.42.96-.62 1.395-1.16 2.235-.755 1.17-1.815 2.625-3.135 2.64-1.17.015-1.47-.765-3.06-.75-1.59.015-1.92.765-3.09.75-1.32-.015-2.325-1.32-3.075-2.49-2.1-3.255-2.325-7.08-1.025-9.105.92-1.44 2.385-2.295 3.755-2.295 1.395 0 2.265.78 3.42.78 1.125 0 1.815-.78 3.435-.78 1.215 0 2.505.66 3.435 1.785-3.015 1.65-2.535 5.97.5 7.23z" />
                  </svg>
                }
              />
            </Magnetic>
            <Magnetic>
              <StoreButton
                storeName="Google Play"
                tagline="Get it on"
                href="#download"
                icon={
                  <svg viewBox="0 0 24 24" className="h-7 w-7" fill="currentColor">
                    <path d="M3.609 1.814L13.792 12 3.61 22.186a.996.996 0 0 1-.61-.92V2.734a1 1 0 0 1 .609-.92zm10.89 10.893l2.302 2.302-10.937 6.323 8.635-8.625zM6.001 1.65l10.928 6.32-2.32 2.32L5.998 1.65zm14.79 8.32c.69.396.69 1.385 0 1.78l-2.434 1.405-2.539-2.295 2.539-2.295 2.434 1.405z" />
                  </svg>
                }
              />
            </Magnetic>
            <a
              href="#features"
              className="group inline-flex items-center gap-2 rounded-full border border-white/10 px-5 py-3 text-sm font-semibold text-cosmic-muted transition-colors hover:border-gold/50 hover:text-cosmic-text"
            >
              See features
              <span aria-hidden className="transition-transform group-hover:translate-x-1">
                →
              </span>
            </a>
          </motion.div>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1.1, duration: 0.8 }}
            className="mt-8 flex items-center gap-5 text-xs text-cosmic-dim"
          >
            <Stars />
            <span>4.9 average · 12,000+ readings cast</span>
          </motion.div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.85, y: 40 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          transition={{ duration: 1.2, delay: 0.2, ease: [0.22, 1, 0.36, 1] }}
          style={reduce ? undefined : { y: phoneY }}
          className="relative mx-auto grid place-items-center"
        >
          <ZodiacWheel className="absolute left-1/2 top-1/2 h-[520px] w-[520px] -translate-x-1/2 -translate-y-1/2 md:h-[640px] md:w-[640px]" />
          <PhoneMock />
        </motion.div>
      </div>

      {/* Scroll cue */}
      <motion.a
        href="#features"
        aria-label="Scroll to features"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.6 }}
        className="absolute bottom-8 left-1/2 hidden -translate-x-1/2 md:block"
      >
        <span className="flex h-10 w-6 justify-center rounded-full border border-white/20 pt-2">
          <span className="h-2 w-1 animate-scroll-dot rounded-full bg-gold" />
        </span>
      </motion.a>
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
