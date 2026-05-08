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

export default function Page() {
  return (
    <main className="relative overflow-x-hidden bg-cosmic-bg text-cosmic-text">
      {/* Ambient cosmic gradient that floats above the solid bg */}
      <div className="pointer-events-none absolute inset-0 bg-cosmic-radial" />
      <div className="relative">
        <Nav />
        <Hero />
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
        <Pricing />
        <DownloadCTA />
        <Footer />
      </div>
    </main>
  );
}
