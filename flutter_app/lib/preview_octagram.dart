// Preview-only entrypoint: runs the real DestinyMatrixScreen with the data
// provider overridden to the reference birthdate (Day->2, Month->10, Year->5),
// so the octagram can be verified in the simulator with real fonts and no
// backend/Firebase/auth. Run with:
//   flutter run -t lib/preview_octagram.dart
//
// Not shipped — excluded from the normal app entrypoint (main.dart).
import 'package:cosmic_mirror/config/theme/app_theme.dart';
import 'package:cosmic_mirror/features/destiny_matrix/domain/entities/destiny_matrix.dart';
import 'package:cosmic_mirror/features/destiny_matrix/presentation/providers/destiny_matrix_providers.dart';
import 'package:cosmic_mirror/features/destiny_matrix/presentation/screens/destiny_matrix_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        destinyMatrixReadingProvider.overrideWith((ref) async => _reference()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: CosmicTheme.lightTheme,
        darkTheme: CosmicTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const DestinyMatrixScreen(),
      ),
    ),
  );
}

int _digitSum(int n) {
  var rest = n.abs();
  var s = 0;
  while (rest > 0) {
    s += rest % 10;
    rest ~/= 10;
  }
  return s;
}

int _reduce(int n) {
  if (n < 1) return 1;
  var v = n;
  while (v > 22) {
    v = _digitSum(v);
  }
  return v;
}

/// [nearP, mid, nearCenter] along the edge from outer point [p] to [center].
List<int> _subdivide(int p, int center) {
  final mid = _reduce(p + center);
  return [_reduce(p + mid), mid, _reduce(mid + center)];
}

DestinyPoint _pt(String key, int arcana, [String title = '']) => DestinyPoint(
      key: key,
      position: key,
      title: title.isEmpty ? key : title,
      arcana: arcana,
      arcanaName: 'Arcana $arcana',
      meaning: '',
    );

DestinyMatrixReading _reference() {
  const day = 2;
  const month = 10;
  const year = 5;
  final sum = _reduce(day + month + year);
  final center = _reduce(day + month + year + sum);

  final tl = _reduce(day + month);
  final tr = _reduce(month + year);
  final br = _reduce(year + sum);
  final bl = _reduce(sum + day);

  final heaven = _reduce(month + sum);
  final earth = _reduce(day + year);
  final personal = _reduce(heaven + earth);

  final left = _subdivide(day, center);
  final top = _subdivide(month, center);
  final right = _subdivide(year, center);
  final bottom = _subdivide(sum, center);
  final dtl = _subdivide(tl, center);
  final dtr = _subdivide(tr, center);
  final dbr = _subdivide(br, center);
  final dbl = _subdivide(bl, center);

  final points = <DestinyPoint>[
    _pt('day', day, 'Day / Self'),
    _pt('month', month, 'Month / Talents'),
    _pt('year', year, 'Year / Ancestry'),
    _pt('sum', sum, 'Purpose / Karma'),
    _pt('tl', tl, 'Material Root'),
    _pt('tr', tr, 'Relationship Root'),
    _pt('br', br, 'Material Outcome'),
    _pt('bl', bl, 'Relationship Outcome'),
    _pt('center', center, 'Comfort / Core'),
    _pt('heaven', heaven, 'Sky Purpose'),
    _pt('earth', earth, 'Earth Purpose'),
    _pt('personal', personal, 'Personal Purpose'),
    _pt('arm_left_1', left[0]),
    _pt('arm_left_2', left[1]),
    _pt('arm_left_3', left[2]),
    _pt('arm_top_1', top[0]),
    _pt('arm_top_2', top[1]),
    _pt('arm_top_3', top[2]),
    _pt('arm_right_1', right[0]),
    _pt('arm_right_2', right[1]),
    _pt('arm_right_3', right[2]),
    _pt('arm_bottom_1', bottom[0]),
    _pt('arm_bottom_2', bottom[1]),
    _pt('arm_bottom_3', bottom[2]),
    _pt('diag_tl_1', dtl[0]),
    _pt('diag_tl_2', dtl[1]),
    _pt('diag_tl_3', dtl[2]),
    _pt('diag_tr_1', dtr[0]),
    _pt('diag_tr_2', dtr[1]),
    _pt('diag_tr_3', dtr[2]),
    _pt('diag_br_1', dbr[0]),
    _pt('diag_br_2', dbr[1]),
    _pt('diag_br_3', dbr[2]),
    _pt('diag_bl_1', dbl[0]),
    _pt('diag_bl_2', dbl[1]),
    _pt('diag_bl_3', dbl[2]),
  ];

  final corners = [day, tl, month, tr, year, br, sum, bl];
  final ladder = <AgeArcana>[];
  for (var d = 0; d < 8; d++) {
    final startAge = d * 10.0;
    final v0 = corners[d];
    final v8 = corners[(d + 1) % 8];
    ladder.add(
      AgeArcana(age: startAge, label: '${startAge.toInt()}', arcana: v0),
    );
    final v4 = _reduce(v0 + v8);
    final v2 = _reduce(v0 + v4);
    final v6 = _reduce(v4 + v8);
    final ticks = [
      _reduce(v0 + v2),
      v2,
      _reduce(v2 + v4),
      v4,
      _reduce(v4 + v6),
      v6,
      _reduce(v6 + v8),
    ];
    for (var i = 0; i < ticks.length; i++) {
      final age = startAge + 1.25 * (i + 1);
      ladder.add(
        AgeArcana(
          age: age,
          label: age.toStringAsFixed(2),
          arcana: ticks[i],
        ),
      );
    }
  }

  final lines = <DestinyLine>[
    const DestinyLine(
      key: 'maleGeneration',
      title: 'Male Generation Line',
      pointKeys: [
        'tl',
        'diag_tl_1',
        'diag_tl_2',
        'diag_tl_3',
        'center',
        'diag_br_3',
        'diag_br_2',
        'diag_br_1',
        'br',
      ],
      theme: 'The paternal diagonal: talents, debts and lessons down the '
          "father's line.",
    ),
    const DestinyLine(
      key: 'femaleGeneration',
      title: 'Female Generation Line',
      pointKeys: [
        'tr',
        'diag_tr_1',
        'diag_tr_2',
        'diag_tr_3',
        'center',
        'diag_bl_3',
        'diag_bl_2',
        'diag_bl_1',
        'bl',
      ],
      theme: 'The maternal diagonal: gifts, wounds and karmic patterns down '
          "the mother's line.",
    ),
  ];

  return DestinyMatrixReading(
    birthDate: '2003-10-02',
    points: points,
    lines: lines,
    ageLadder: ladder,
  );
}
