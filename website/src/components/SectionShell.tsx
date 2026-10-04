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
        <div className={align === "center" ? "text-center" : ""}>
          {eyebrow && (
            <motion.div
              initial={{ opacity: 0, x: align === "center" ? 0 : -16 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true, amount: 0.6 }}
              transition={{ duration: 0.6, ease: "easeOut" }}
              className={`mb-4 flex items-center gap-3 text-xs font-bold uppercase tracking-[0.18em] text-gold ${
                align === "center" ? "justify-center" : ""
              }`}
            >
              <motion.span
                aria-hidden
                initial={{ scaleX: 0 }}
                whileInView={{ scaleX: 1 }}
                viewport={{ once: true }}
                transition={{ duration: 0.8, delay: 0.1, ease: [0.22, 1, 0.36, 1] }}
                className="h-px w-10 origin-left bg-gold-gradient"
              />
              {eyebrow}
            </motion.div>
          )}
          <motion.h2
            initial={{ opacity: 0, y: 36, filter: "blur(10px)" }}
            whileInView={{ opacity: 1, y: 0, filter: "blur(0px)" }}
            viewport={{ once: true, amount: 0.5 }}
            transition={{ duration: 0.9, ease: [0.22, 1, 0.36, 1] }}
            className="font-display text-3xl font-extrabold leading-tight tracking-tight md:text-5xl"
          >
            {title}
          </motion.h2>
          {blurb && (
            <motion.p
              initial={{ opacity: 0, y: 16 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, amount: 0.5 }}
              transition={{ duration: 0.8, delay: 0.15, ease: "easeOut" }}
              className={`mt-5 max-w-2xl text-base leading-relaxed text-cosmic-muted md:text-lg ${
                align === "center" ? "mx-auto" : ""
              }`}
            >
              {blurb}
            </motion.p>
          )}
        </div>
        {children && <div className="mt-12 md:mt-16">{children}</div>}
      </div>
    </section>
  );
}
