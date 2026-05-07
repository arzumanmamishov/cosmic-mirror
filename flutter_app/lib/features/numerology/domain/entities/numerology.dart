import 'package:equatable/equatable.dart';

/// One calculated numerology number with provenance + description.
class NumerologyNumber extends Equatable {
  const NumerologyNumber({
    required this.value,
    required this.display,
    required this.rawSum,
    required this.isMaster,
    required this.isKarmicDebt,
    required this.description,
  });

  factory NumerologyNumber.fromJson(Map<String, dynamic> json) {
    return NumerologyNumber(
      value: (json['value'] as num?)?.toInt() ?? 0,
      display: json['display'] as String? ?? '',
      rawSum: (json['raw_sum'] as num?)?.toInt() ?? 0,
      isMaster: json['is_master'] as bool? ?? false,
      isKarmicDebt: json['is_karmic_debt'] as bool? ?? false,
      description: json['description'] as String? ?? '',
    );
  }

  /// 1..9 for normal numbers; 11/22/33 for master numbers.
  final int value;

  /// What the UI should show — "11/2", "22/4", or just "5".
  final String display;

  /// Pre-reduction sum (e.g. 29 → 11 → 2 has rawSum=29).
  final int rawSum;
  final bool isMaster;
  final bool isKarmicDebt;
  final String description;

  @override
  List<Object?> get props => [value, isMaster, isKarmicDebt];
}

class NumerologyProfile extends Equatable {
  const NumerologyProfile({
    required this.lifePath,
    required this.expression,
    required this.soulUrge,
    required this.personality,
    required this.maturity,
    required this.birthday,
    required this.karmicLessons,
    required this.hiddenPassion,
    required this.fullName,
    required this.birthDate,
  });

  factory NumerologyProfile.fromJson(Map<String, dynamic> json) {
    return NumerologyProfile(
      lifePath: NumerologyNumber.fromJson(
        (json['life_path'] as Map<String, dynamic>?) ?? const {},
      ),
      expression: NumerologyNumber.fromJson(
        (json['expression'] as Map<String, dynamic>?) ?? const {},
      ),
      soulUrge: NumerologyNumber.fromJson(
        (json['soul_urge'] as Map<String, dynamic>?) ?? const {},
      ),
      personality: NumerologyNumber.fromJson(
        (json['personality'] as Map<String, dynamic>?) ?? const {},
      ),
      maturity: NumerologyNumber.fromJson(
        (json['maturity'] as Map<String, dynamic>?) ?? const {},
      ),
      birthday: NumerologyNumber.fromJson(
        (json['birthday'] as Map<String, dynamic>?) ?? const {},
      ),
      karmicLessons: ((json['karmic_lessons'] as List<dynamic>?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      hiddenPassion: (json['hidden_passion'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String? ?? '',
      birthDate: DateTime.tryParse(json['birth_date'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final NumerologyNumber lifePath;
  final NumerologyNumber expression;
  final NumerologyNumber soulUrge;
  final NumerologyNumber personality;
  final NumerologyNumber maturity;
  final NumerologyNumber birthday;
  final List<int> karmicLessons;
  final int hiddenPassion;
  final String fullName;
  final DateTime birthDate;

  @override
  List<Object?> get props => [lifePath, expression, fullName];
}

class PinnacleCycle extends Equatable {
  const PinnacleCycle({
    required this.index,
    required this.startAge,
    required this.endAge,
    required this.number,
    required this.isActive,
  });

  factory PinnacleCycle.fromJson(Map<String, dynamic> json) {
    return PinnacleCycle(
      index: (json['index'] as num?)?.toInt() ?? 0,
      startAge: (json['start_age'] as num?)?.toInt() ?? 0,
      endAge: (json['end_age'] as num?)?.toInt() ?? -1,
      number: NumerologyNumber.fromJson(
        (json['number'] as Map<String, dynamic>?) ?? const {},
      ),
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  final int index;
  final int startAge;

  /// -1 means "rest of life".
  final int endAge;
  final NumerologyNumber number;
  final bool isActive;

  @override
  List<Object?> get props => [index, isActive];
}

class ChallengeCycle extends Equatable {
  const ChallengeCycle({
    required this.index,
    required this.startAge,
    required this.endAge,
    required this.number,
    required this.isActive,
  });

  factory ChallengeCycle.fromJson(Map<String, dynamic> json) {
    return ChallengeCycle(
      index: (json['index'] as num?)?.toInt() ?? 0,
      startAge: (json['start_age'] as num?)?.toInt() ?? 0,
      endAge: (json['end_age'] as num?)?.toInt() ?? -1,
      number: NumerologyNumber.fromJson(
        (json['number'] as Map<String, dynamic>?) ?? const {},
      ),
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  final int index;
  final int startAge;
  final int endAge;
  final NumerologyNumber number;
  final bool isActive;

  @override
  List<Object?> get props => [index, isActive];
}

class NumerologyCycles extends Equatable {
  const NumerologyCycles({
    required this.personalYear,
    required this.personalMonth,
    required this.personalDay,
    required this.pinnacles,
    required this.challenges,
    required this.currentAge,
  });

  factory NumerologyCycles.fromJson(Map<String, dynamic> json) {
    final pinList = (json['pinnacles'] as List<dynamic>?) ?? const [];
    final chList = (json['challenges'] as List<dynamic>?) ?? const [];
    return NumerologyCycles(
      personalYear: NumerologyNumber.fromJson(
        (json['personal_year'] as Map<String, dynamic>?) ?? const {},
      ),
      personalMonth: NumerologyNumber.fromJson(
        (json['personal_month'] as Map<String, dynamic>?) ?? const {},
      ),
      personalDay: NumerologyNumber.fromJson(
        (json['personal_day'] as Map<String, dynamic>?) ?? const {},
      ),
      pinnacles: pinList
          .map((e) => PinnacleCycle.fromJson(e as Map<String, dynamic>))
          .toList(),
      challenges: chList
          .map((e) => ChallengeCycle.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentAge: (json['current_age'] as num?)?.toInt() ?? 0,
    );
  }

  final NumerologyNumber personalYear;
  final NumerologyNumber personalMonth;
  final NumerologyNumber personalDay;
  final List<PinnacleCycle> pinnacles;
  final List<ChallengeCycle> challenges;
  final int currentAge;

  @override
  List<Object?> get props => [personalYear, personalMonth, personalDay, currentAge];
}

class NumerologyReading extends Equatable {
  const NumerologyReading({required this.profile, required this.cycles});

  factory NumerologyReading.fromJson(Map<String, dynamic> json) {
    return NumerologyReading(
      profile: NumerologyProfile.fromJson(
        (json['profile'] as Map<String, dynamic>?) ?? const {},
      ),
      cycles: NumerologyCycles.fromJson(
        (json['cycles'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  final NumerologyProfile profile;
  final NumerologyCycles cycles;

  @override
  List<Object?> get props => [profile, cycles];
}

class NumerologyCompatibility extends Equatable {
  const NumerologyCompatibility({
    required this.score,
    required this.lifePathScore,
    required this.expressionScore,
    required this.soulUrgeScore,
    required this.summary,
    required this.otherProfile,
  });

  factory NumerologyCompatibility.fromJson(Map<String, dynamic> json) {
    return NumerologyCompatibility(
      score: (json['score'] as num?)?.toInt() ?? 0,
      lifePathScore: (json['life_path_score'] as num?)?.toInt() ?? 0,
      expressionScore: (json['expression_score'] as num?)?.toInt() ?? 0,
      soulUrgeScore: (json['soul_urge_score'] as num?)?.toInt() ?? 0,
      summary: json['summary'] as String? ?? '',
      otherProfile: NumerologyProfile.fromJson(
        (json['other_profile'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  final int score;
  final int lifePathScore;
  final int expressionScore;
  final int soulUrgeScore;
  final String summary;
  final NumerologyProfile otherProfile;

  @override
  List<Object?> get props => [score];
}

/// One letter in a name analysis with its Pythagorean digit + vowel flag.
/// Used by the Name Calculator UI to show how each total was built.
class NumerologyLetter extends Equatable {
  const NumerologyLetter({
    required this.letter,
    required this.value,
    required this.isVowel,
  });

  factory NumerologyLetter.fromJson(Map<String, dynamic> json) {
    return NumerologyLetter(
      letter: json['letter'] as String? ?? '',
      value: (json['value'] as num?)?.toInt() ?? 0,
      isVowel: json['is_vowel'] as bool? ?? false,
    );
  }

  final String letter;
  final int value;
  final bool isVowel;

  @override
  List<Object?> get props => [letter, value, isVowel];
}

/// The standalone Name Numerology Calculator response — the three
/// classical name-derived numbers + the per-letter trace.
class NumerologyNameAnalysis extends Equatable {
  const NumerologyNameAnalysis({
    required this.name,
    required this.expression,
    required this.soulUrge,
    required this.personality,
    required this.hiddenPassion,
    required this.karmicLessons,
    required this.letters,
  });

  factory NumerologyNameAnalysis.fromJson(Map<String, dynamic> json) {
    final letterList = (json['letters'] as List<dynamic>?) ?? const [];
    return NumerologyNameAnalysis(
      name: json['name'] as String? ?? '',
      expression: NumerologyNumber.fromJson(
        (json['expression'] as Map<String, dynamic>?) ?? const {},
      ),
      soulUrge: NumerologyNumber.fromJson(
        (json['soul_urge'] as Map<String, dynamic>?) ?? const {},
      ),
      personality: NumerologyNumber.fromJson(
        (json['personality'] as Map<String, dynamic>?) ?? const {},
      ),
      hiddenPassion: (json['hidden_passion'] as num?)?.toInt() ?? 0,
      karmicLessons: ((json['karmic_lessons'] as List<dynamic>?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      letters: letterList
          .map((e) => NumerologyLetter.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String name;
  final NumerologyNumber expression;
  final NumerologyNumber soulUrge;
  final NumerologyNumber personality;
  final int hiddenPassion;
  final List<int> karmicLessons;
  final List<NumerologyLetter> letters;

  @override
  List<Object?> get props => [name, expression, soulUrge, personality];
}
