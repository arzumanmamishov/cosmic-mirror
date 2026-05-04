import 'package:equatable/equatable.dart';

class HDCenter extends Equatable {
  const HDCenter({
    required this.name,
    required this.defined,
    required this.gates,
  });

  factory HDCenter.fromJson(Map<String, dynamic> json) {
    return HDCenter(
      name: json['name'] as String? ?? '',
      defined: json['defined'] as bool? ?? false,
      gates: ((json['gates'] as List<dynamic>?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
    );
  }

  final String name;
  final bool defined;
  final List<int> gates;

  @override
  List<Object?> get props => [name, defined, gates];
}

class HDGateActivation extends Equatable {
  const HDGateActivation({
    required this.gate,
    required this.line,
    required this.body,
    required this.isPersonality,
  });

  factory HDGateActivation.fromJson(Map<String, dynamic> json) {
    return HDGateActivation(
      gate: (json['gate'] as num?)?.toInt() ?? 0,
      line: (json['line'] as num?)?.toInt() ?? 0,
      body: json['body'] as String? ?? '',
      isPersonality: json['is_personality'] as bool? ?? false,
    );
  }

  final int gate;
  final int line;
  final String body;
  final bool isPersonality;

  @override
  List<Object?> get props => [gate, line, body, isPersonality];
}

class HDChannel extends Equatable {
  const HDChannel({
    required this.gate1,
    required this.gate2,
    required this.name,
    required this.centers,
  });

  factory HDChannel.fromJson(Map<String, dynamic> json) {
    return HDChannel(
      gate1: (json['gate1'] as num?)?.toInt() ?? 0,
      gate2: (json['gate2'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      centers: ((json['centers'] as List<dynamic>?) ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }

  final int gate1;
  final int gate2;
  final String name;
  final List<String> centers;

  @override
  List<Object?> get props => [gate1, gate2];
}

class HDCross extends Equatable {
  const HDCross({
    required this.name,
    required this.quarter,
    required this.gates,
  });

  factory HDCross.fromJson(Map<String, dynamic> json) {
    final raw = (json['gates'] as List<dynamic>?) ?? const [];
    return HDCross(
      name: json['name'] as String? ?? '',
      quarter: json['quarter'] as String? ?? '',
      gates: List<int>.generate(
        4,
        (i) => i < raw.length ? (raw[i] as num).toInt() : 0,
      ),
    );
  }

  final String name;
  final String quarter;
  final List<int> gates; // length 4

  @override
  List<Object?> get props => [name, gates];
}

class HDVariables extends Equatable {
  const HDVariables({
    required this.digestion,
    required this.environment,
    required this.awareness,
    required this.perspective,
  });

  factory HDVariables.fromJson(Map<String, dynamic> json) {
    return HDVariables(
      digestion: json['digestion'] as String? ?? '',
      environment: json['environment'] as String? ?? '',
      awareness: json['awareness'] as String? ?? '',
      perspective: json['perspective'] as String? ?? '',
    );
  }

  final String digestion; // Left | Right
  final String environment;
  final String awareness;
  final String perspective;

  @override
  List<Object?> get props =>
      [digestion, environment, awareness, perspective];
}

class HumanDesignChart extends Equatable {
  const HumanDesignChart({
    required this.type,
    required this.strategy,
    required this.authority,
    required this.profile,
    required this.definition,
    required this.notSelfTheme,
    required this.centers,
    required this.gates,
    required this.channels,
    required this.incarnationCross,
    required this.variables,
  });

  factory HumanDesignChart.fromJson(Map<String, dynamic> json) {
    return HumanDesignChart(
      type: json['type'] as String? ?? '',
      strategy: json['strategy'] as String? ?? '',
      authority: json['authority'] as String? ?? '',
      profile: json['profile'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      notSelfTheme: json['not_self_theme'] as String? ?? '',
      centers: ((json['centers'] as List<dynamic>?) ?? const [])
          .map((e) => HDCenter.fromJson(e as Map<String, dynamic>))
          .toList(),
      gates: ((json['gates'] as List<dynamic>?) ?? const [])
          .map((e) => HDGateActivation.fromJson(e as Map<String, dynamic>))
          .toList(),
      channels: ((json['channels'] as List<dynamic>?) ?? const [])
          .map((e) => HDChannel.fromJson(e as Map<String, dynamic>))
          .toList(),
      incarnationCross: HDCross.fromJson(
        (json['incarnation_cross'] as Map<String, dynamic>?) ?? const {},
      ),
      variables: HDVariables.fromJson(
        (json['variables'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  final String type;
  final String strategy;
  final String authority;
  final String profile;
  final String definition;
  final String notSelfTheme;
  final List<HDCenter> centers;
  final List<HDGateActivation> gates;
  final List<HDChannel> channels;
  final HDCross incarnationCross;
  final HDVariables variables;

  @override
  List<Object?> get props => [type, profile, definition];
}
