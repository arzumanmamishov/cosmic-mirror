import { Nav } from "@/components/Nav";
import { Hero } from "@/components/Hero";
import { FeatureGrid } from "@/components/FeatureGrid";
import { ChartShowcase } from "@/components/ChartShowcase";
import { VedicShowcase } from "@/components/VedicShowcase";
import { NumerologyShowcase } from "@/components/NumerologyShowcase";
import { HumanDesignShowcase } from "@/components/HumanDesignShowcase";
import { AIAstrologer } from "@/components/AIAstrologer";
import { Compatibility } from "@/components/Compatibility";
import { Timeline } from "@/components/Timeline";
import { JournalAndRituals } from "@/components/JournalAndRituals";
import { Community } from "@/components/Community";
import { Languages } from "@/components/Languages";
import { Pricing } from "@/components/Pricing";
import { DownloadCTA } from "@/components/DownloadCTA";
import { Footer } from "@/components/Footer";
import { CosmicBackground } from "@/components/fx/CosmicBackground";
import {
  CursorGlow,
  Marquee,
  ScrollProgress,
} from "@/components/fx/Effects";

const SIGNS = [
  "♈ Aries", "♉ Taurus", "♊ Gemini", "♋ Cancer", "♌ Leo", "♍ Virgo",
  "♎ Libra", "♏ Scorpio", "♐ Sagittarius", "♑ Capricorn", "♒ Aquarius", "♓ Pisces",
];
const SYSTEMS = [
  "Natal chart", "Vedic kundli", "Dasha periods", "Numerology",
  "Human Design", "AI astrologer", "Compatibility", "Daily reading",
];

export default function Page() {
  return (
    <main className="relative overflow-x-hidden text-cosmic-text">
      {/* Living sky: starfield canvas + drifting nebulae, fixed behind
          everything (the page background itself comes from <body>). */}
      <CosmicBackground />
      <CursorGlow />
      <ScrollProgress />
      <div className="pointer-events-none absolute inset-0 bg-cosmic-radial" />
      <div className="relative">
        <Nav />
        <Hero />
        <div className="space-y-4 border-y border-white/5 bg-white/[0.015] py-8 backdrop-blur-[2px]">
          <Marquee items={SIGNS} />
          <Marquee items={SYSTEMS} reverse />
        </div>
        <FeatureGrid />
        <ChartShowcase />
        <VedicShowcase />
        <NumerologyShowcase />
        <HumanDesignShowcase />
        <AIAstrologer />
        <Compatibility />
        <Timeline />
        <JournalAndRituals />
        <Community />
        <Languages />
        <div className="py-6">
          <Marquee items={SYSTEMS} />
        </div>
        <Pricing />
        <DownloadCTA />
        <Footer />
      </div>
    </main>
  );
}
