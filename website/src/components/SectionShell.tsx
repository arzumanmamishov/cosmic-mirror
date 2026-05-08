"use client";

import { motion } from "framer-motion";
import type { ReactNode } from "react";

/// Reusable section wrapper that gives every alternating block its
/// scroll-revealed entrance + consistent vertical rhythm and a
/// faint divider line at the top.
export function SectionShell({
  id,
  eyebrow,
  title,
  blurb,
  children,
  align = "left",
}: {
  id?: string;
  eyebrow?: string;
  title: ReactNode;
  blurb?: string;
  children?: ReactNode;
  align?: "left" | "center";
}) {
  return (
    <section id={id} className="section-y relative">
      <div className="mx-auto max-w-7xl px-5 md:px-8">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, amount: 0.3 }}
          transition={{ duration: 0.7, ease: "easeOut" }}
          className={align === "center" ? "text-center" : ""}
        >
          {eyebrow && (
            <div className="mb-3 text-xs font-bold uppercase tracking-[0.18em] text-gold">
              {eyebrow}
            </div>
          )}
          <h2 className="font-display text-3xl font-extrabold leading-tight tracking-tight md:text-5xl">
            {title}
          </h2>
          {blurb && (
            <p
              className={`mt-5 max-w-2xl text-base leading-relaxed text-cosmic-muted md:text-lg ${
                align === "center" ? "mx-auto" : ""
              }`}
            >
              {blurb}
            </p>
          )}
        </motion.div>
        {children && <div className="mt-12 md:mt-16">{children}</div>}
      </div>
    </section>
  );
}
