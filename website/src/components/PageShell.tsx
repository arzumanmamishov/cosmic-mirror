import type { ReactNode } from "react";
import { Nav } from "@/components/Nav";
import { Footer } from "@/components/Footer";

/// Shared shell for long-form content routes (privacy, terms, support).
/// Reuses the landing page's Nav + Footer and the same cosmic backdrop so
/// these pages read as native parts of the site. The actual prose is styled
/// by the `.legal-prose` component class in globals.css.
export function PageShell({
  eyebrow,
  title,
  lastUpdated,
  intro,
  children,
}: {
  eyebrow?: string;
  title: ReactNode;
  lastUpdated: string;
  intro?: ReactNode;
  children: ReactNode;
}) {
  return (
    <main className="relative min-h-screen overflow-x-hidden bg-cosmic-bg text-cosmic-text">
      {/* Ambient cosmic gradient that floats above the solid bg */}
      <div className="pointer-events-none absolute inset-0 bg-cosmic-radial" />
      <div className="relative">
        <Nav />

        <header className="mx-auto max-w-3xl px-5 pt-32 md:px-8 md:pt-40">
          {eyebrow && (
            <div className="mb-3 text-xs font-bold uppercase tracking-[0.18em] text-gold">
              {eyebrow}
            </div>
          )}
          <h1 className="font-display text-4xl font-black leading-tight tracking-tight md:text-6xl">
            {title}
          </h1>
          <p className="mt-5 text-sm text-cosmic-dim">
            Last updated: {lastUpdated}
          </p>
          {intro && (
            <p className="mt-6 text-base leading-relaxed text-cosmic-muted md:text-lg">
              {intro}
            </p>
          )}
        </header>

        <article className="legal-prose mx-auto max-w-3xl px-5 pb-24 pt-10 md:px-8 md:pb-32">
          {children}
        </article>

        <Footer />
      </div>
    </main>
  );
}
