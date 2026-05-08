import type { Config } from "tailwindcss";

/// Theme tokens mirror the Flutter app's AppPalette so the site's
/// first impression visually flows into the app the user downloads.
const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        cosmic: {
          bg: "#1A1F2E",
          surface: "#222837",
          elevated: "#2A2F3E",
          border: "#3A4055",
          text: "#E6EAF2",
          muted: "#B6BAC4",
          dim: "#7E8290",
        },
        gold: {
          DEFAULT: "#D4B16A",
          light: "#E9D49A",
          dark: "#9F7637",
          pale: "#FFE9B8",
        },
        accent: {
          violet: "#7B61FF",
          rose: "#E14B8A",
          amber: "#F4C542",
          teal: "#5CC9C0",
        },
      },
      fontFamily: {
        sans: ['"Inter"', "ui-sans-serif", "system-ui", "sans-serif"],
        display: ['"Poppins"', '"Inter"', "ui-sans-serif", "sans-serif"],
      },
      backgroundImage: {
        "gold-gradient":
          "linear-gradient(135deg, #E9D49A 0%, #D4B16A 50%, #9F7637 100%)",
        "cosmic-radial":
          "radial-gradient(1200px 600px at 50% -10%, rgba(212,177,106,0.18), transparent 60%), radial-gradient(800px 400px at 100% 100%, rgba(123,97,255,0.10), transparent 60%)",
      },
      boxShadow: {
        "gold-glow": "0 0 40px rgba(212,177,106,0.25)",
        "card": "0 8px 24px rgba(0,0,0,0.35)",
      },
      keyframes: {
        twinkle: {
          "0%,100%": { opacity: "0.25" },
          "50%": { opacity: "0.85" },
        },
        floaty: {
          "0%,100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-8px)" },
        },
      },
      animation: {
        twinkle: "twinkle 4s ease-in-out infinite",
        floaty: "floaty 6s ease-in-out infinite",
      },
    },
  },
  plugins: [],
};

export default config;
