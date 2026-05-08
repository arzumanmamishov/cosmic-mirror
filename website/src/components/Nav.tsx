"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";

const links = [
  { href: "#features", label: "Features" },
  { href: "#charts", label: "Charts" },
  { href: "#ai", label: "AI Astrologer" },
  { href: "#community", label: "Community" },
  { href: "#pricing", label: "Pricing" },
];

export function Nav() {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 16);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <header
      className={`fixed inset-x-0 top-0 z-50 transition-all duration-300 ${
        scrolled
          ? "border-b border-white/5 bg-cosmic-bg/80 backdrop-blur-xl"
          : "bg-transparent"
      }`}
    >
      <div className="mx-auto flex max-w-7xl items-center justify-between px-5 py-4 md:px-8">
        <Link href="/" className="group flex items-center gap-2.5">
          <Image
            src="/lively_logo.png"
            alt="Lively"
            width={36}
            height={36}
            priority
            className="h-9 w-9 drop-shadow-[0_0_12px_rgba(212,177,106,0.35)]"
          />
          <span className="font-display text-xl font-extrabold tracking-tight">
            Lively
          </span>
        </Link>
        <nav className="hidden items-center gap-7 md:flex">
          {links.map((l) => (
            <a
              key={l.href}
              href={l.href}
              className="text-sm font-medium text-cosmic-muted transition-colors hover:text-cosmic-text"
            >
              {l.label}
            </a>
          ))}
        </nav>
        <a
          href="#download"
          className="rounded-full bg-gold-gradient px-4 py-2 text-sm font-bold text-[#1a1f2e] shadow-gold-glow transition-transform hover:scale-105"
        >
          Get the app
        </a>
      </div>
    </header>
  );
}
