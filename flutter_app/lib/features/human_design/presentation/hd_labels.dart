import 'package:cosmic_mirror/l10n/app_localizations.dart';

/// Localized display names for the enum-like English identifiers the backend
/// returns in a Human Design chart (types, strategies, authorities, centers,
/// channels, ...). The raw values stay untouched in the entities; these
/// helpers only map them for display and fall back to the raw value for
/// anything unknown.
class HDLabels {
  const HDLabels(this.l);

  final AppLocalizations l;

  String type(String raw) => switch (raw) {
        'Manifestor' => l.hdTypeManifestor,
        'Generator' => l.hdTypeGenerator,
        'Manifesting Generator' => l.hdTypeManifestingGenerator,
        'Projector' => l.hdTypeProjector,
        'Reflector' => l.hdTypeReflector,
        _ => raw,
      };

  String strategy(String raw) => switch (raw) {
        'Inform before acting' => l.hdStrategyInform,
        'Wait to respond' => l.hdStrategyRespond,
        'Wait to respond, then inform' => l.hdStrategyRespondInform,
        'Wait for the invitation' => l.hdStrategyInvitation,
        'Wait a lunar cycle (28 days)' => l.hdStrategyLunarCycle,
        _ => raw,
      };

  String authority(String raw) => switch (raw) {
        'Emotional' => l.hdAuthorityEmotional,
        'Sacral' => l.hdAuthoritySacral,
        'Splenic' => l.hdAuthoritySplenic,
        'Ego' => l.hdAuthorityEgo,
        'Self-Projected' => l.hdAuthoritySelfProjected,
        'Mental' => l.hdAuthorityMental,
        'Lunar' => l.hdAuthorityLunar,
        _ => raw,
      };

  String definition(String raw) => switch (raw) {
        'None' => l.hdDefinitionNone,
        'Single' => l.hdDefinitionSingle,
        'Split' => l.hdDefinitionSplit,
        'Triple Split' => l.hdDefinitionTripleSplit,
        'Quadruple Split' => l.hdDefinitionQuadrupleSplit,
        _ => raw,
      };

  String notSelf(String raw) => switch (raw) {
        'Anger' => l.hdNotSelfAnger,
        'Frustration' => l.hdNotSelfFrustration,
        'Frustration & Anger' => l.hdNotSelfFrustrationAnger,
        'Bitterness' => l.hdNotSelfBitterness,
        'Disappointment' => l.hdNotSelfDisappointment,
        _ => raw,
      };

  String center(String raw) => switch (raw) {
        'Head' => l.hdCenterHead,
        'Ajna' => l.hdCenterAjna,
        'Throat' => l.hdCenterThroat,
        'G' => l.hdCenterG,
        'Heart' => l.hdCenterHeart,
        'Sacral' => l.hdCenterSacral,
        'SolarPlexus' || 'Solar Plexus' => l.hdCenterSolarPlexus,
        'Spleen' => l.hdCenterSpleen,
        'Root' => l.hdCenterRoot,
        _ => raw,
      };

  /// Short theme line shown under each center card; empty when unknown.
  String centerTheme(String raw) => switch (raw) {
        'Head' => l.hdCenterThemeHead,
        'Ajna' => l.hdCenterThemeAjna,
        'Throat' => l.hdCenterThemeThroat,
        'G' => l.hdCenterThemeG,
        'Heart' => l.hdCenterThemeHeart,
        'Sacral' => l.hdCenterThemeSacral,
        'SolarPlexus' || 'Solar Plexus' => l.hdCenterThemeSolarPlexus,
        'Spleen' => l.hdCenterThemeSpleen,
        'Root' => l.hdCenterThemeRoot,
        _ => '',
      };

  String direction(String raw) => switch (raw.toLowerCase()) {
        'left' => l.hdDirectionLeft,
        'right' => l.hdDirectionRight,
        _ => raw,
      };

  String quarter(String raw) => switch (raw) {
        'Initiation' => l.hdQuarterInitiation,
        'Civilization' => l.hdQuarterCivilization,
        'Duality' => l.hdQuarterDuality,
        'Mutation' => l.hdQuarterMutation,
        _ => raw,
      };

  /// Backend formats cross names as "Cross of (a/b | c/d)".
  String crossName(String raw) {
    const prefix = 'Cross of ';
    if (raw.startsWith(prefix)) {
      return l.hdCrossOf(raw.substring(prefix.length));
    }
    return raw;
  }

  String body(String raw) => switch (raw) {
        'Sun' => l.hdBodySun,
        'Earth' => l.hdBodyEarth,
        'NorthNode' || 'North Node' => l.hdBodyNorthNode,
        'SouthNode' || 'South Node' => l.hdBodySouthNode,
        'Moon' => l.hdBodyMoon,
        'Mercury' => l.hdBodyMercury,
        'Venus' => l.hdBodyVenus,
        'Mars' => l.hdBodyMars,
        'Jupiter' => l.hdBodyJupiter,
        'Saturn' => l.hdBodySaturn,
        'Uranus' => l.hdBodyUranus,
        'Neptune' => l.hdBodyNeptune,
        'Pluto' => l.hdBodyPluto,
        _ => raw,
      };

  String channel(String raw) => switch (raw) {
        'Inspiration' => l.hdChannelInspiration,
        'The Beat' => l.hdChannelTheBeat,
        'Mutation' => l.hdChannelMutation,
        'Logic' => l.hdChannelLogic,
        'Rhythm' => l.hdChannelRhythm,
        'Mating' => l.hdChannelMating,
        'Alpha (Leadership)' => l.hdChannelAlpha,
        'Concentration' => l.hdChannelConcentration,
        'Awakening' => l.hdChannelAwakening,
        'Exploration' => l.hdChannelExploration,
        'Perfected Form' => l.hdChannelPerfectedForm,
        'Curiosity' => l.hdChannelCuriosity,
        'Openness' => l.hdChannelOpenness,
        'The Prodigal' => l.hdChannelTheProdigal,
        'The Wavelength' => l.hdChannelTheWavelength,
        'Acceptance' => l.hdChannelAcceptance,
        'Judgement' => l.hdChannelJudgement,
        'Synthesis' => l.hdChannelSynthesis,
        'Charisma' => l.hdChannelCharisma,
        'The Brain Wave' => l.hdChannelTheBrainWave,
        'Money Line' => l.hdChannelMoneyLine,
        'Structuring' => l.hdChannelStructuring,
        'Awareness' => l.hdChannelAwareness,
        'Initiation' => l.hdChannelInitiation,
        'Surrender' => l.hdChannelSurrender,
        'Preservation' => l.hdChannelPreservation,
        'Struggle' => l.hdChannelStruggle,
        'Discovery' => l.hdChannelDiscovery,
        'Recognition' => l.hdChannelRecognition,
        'Transformation' => l.hdChannelTransformation,
        'Power' => l.hdChannelPower,
        'Transitoriness' => l.hdChannelTransitoriness,
        'Community' => l.hdChannelCommunity,
        'Emoting' => l.hdChannelEmoting,
        'Maturation' => l.hdChannelMaturation,
        'Abstraction' => l.hdChannelAbstraction,
        _ => raw,
      };
}
