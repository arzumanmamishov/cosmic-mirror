// Shared test fixtures for the Matrix of Destiny: builds a full reading from a
// birth date using the authentic backend algorithm (digit-sum reduce + edge
// subdivision), so widget/golden tests run without a backend.
import 'package:cosmic_mirror/features/destiny_matrix/domain/entities/destiny_matrix.dart';

int _digitSum(int n) {
  var rest = n.abs();
  var s = 0;
  while (rest > 0) {
    s += rest % 10;
    rest ~/= 10;
  }
  return s;
}

/// Folds [n] into 1..22 via the digit-sum method (mirrors the Go backend).
int reduceArcana(int n) {
  if (n < 1) return 1;
  var v = n;
  while (v > 22) {
    v = _digitSum(v);
  }
  return v;
}

/// [nearP, mid, nearCenter] along the edge from outer point [p] to [center].
List<int> _subdivide(int p, int center) {
  final mid = reduceArcana(p + center);
  return [reduceArcana(p + mid), mid, reduceArcana(mid + center)];
}

const _titles = <String, String>{
  'day': 'Day / Self',
  'month': 'Month / Talents',
  'year': 'Year / Ancestry',
  'sum': 'Purpose / Karma',
  'tl': 'Material Root',
  'tr': 'Relationship Root',
  'br': 'Material Outcome',
  'bl': 'Relationship Outcome',
  'center': 'Comfort / Core',
  'heaven': 'Sky Purpose',
  'earth': 'Earth Purpose',
  'personal': 'Personal Purpose',
};

DestinyPoint _pt(String key, int arcana) => DestinyPoint(
      key: key,
      position: key,
      title: _titles[key] ?? key,
      arcana: arcana,
      arcanaName: 'Arcana $arcana',
      meaning: 'Meaning of arcana $arcana.',
    );

List<AgeArcana> _ladder(List<int> corners) {
  final ladder = <AgeArcana>[];
  for (var d = 0; d < 8; d++) {
    final startAge = d * 10.0;
    final v0 = corners[d];
    final v8 = corners[(d + 1) % 8];
    ladder.add(
      AgeArcana(age: startAge, label: '${startAge.toInt()}', arcana: v0),
    );
    final v4 = reduceArcana(v0 + v8);
    final v2 = reduceArcana(v0 + v4);
    final v6 = reduceArcana(v4 + v8);
    final ticks = [
      reduceArcana(v0 + v2),
      v2,
      reduceArcana(v2 + v4),
      v4,
      reduceArcana(v4 + v6),
      v6,
      reduceArcana(v6 + v8),
    ];
    for (var i = 0; i < ticks.length; i++) {
      final age = startAge + 1.25 * (i + 1);
      ladder.add(
        AgeArcana(age: age, label: age.toStringAsFixed(2), arcana: ticks[i]),
      );
    }
  }
  return ladder;
}

/// Builds a full reading from reduced (day, month, year) inputs.
DestinyMatrixReading buildReading({
  required int day,
  required int month,
  required int year,
  String birthDate = '2003-10-02',
}) {
  final sum = reduceArcana(day + month + year);
  final center = reduceArcana(day + month + year + sum);
  final tl = reduceArcana(day + month);
  final tr = reduceArcana(month + year);
  final br = reduceArcana(year + sum);
  final bl = reduceArcana(sum + day);
  final heaven = reduceArcana(month + sum);
  final earth = reduceArcana(day + year);
  final personal = reduceArcana(heaven + earth);

  final left = _subdivide(day, center);
  final top = _subdivide(month, center);
  final right = _subdivide(year, center);
  final bottom = _subdivide(sum, center);
  final dtl = _subdivide(tl, center);
  final dtr = _subdivide(tr, center);
  final dbr = _subdivide(br, center);
  final dbl = _subdivide(bl, center);

  final points = <DestinyPoint>[
    _pt('day', day),
    _pt('month', month),
    _pt('year', year),
    _pt('sum', sum),
    _pt('tl', tl),
    _pt('tr', tr),
    _pt('br', br),
    _pt('bl', bl),
    _pt('center', center),
    _pt('heaven', heaven),
    _pt('earth', earth),
    _pt('personal', personal),
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

  return DestinyMatrixReading(
    birthDate: birthDate,
    points: points,
    lines: const [],
    ageLadder: _ladder([day, tl, month, tr, year, br, sum, bl]),
  );
}

/// The reference-chart example (Day->2, Month->10, Year->5).
DestinyMatrixReading referenceReading() =>
    buildReading(day: 2, month: 10, year: 5);

/// Worst-case text-fit reading: every node and tick shows the two-digit [v]
/// (e.g. 22), to verify the node circles never overflow.
DestinyMatrixReading uniformReading(int v) {
  final keys = <String>[
    'day', 'month', 'year', 'sum', 'tl', 'tr', 'br', 'bl', 'center',
    'heaven', 'earth', 'personal',
    for (final a in ['left', 'top', 'right', 'bottom'])
      for (var i = 1; i <= 3; i++) 'arm_${a}_$i',
    for (final d in ['tl', 'tr', 'br', 'bl'])
      for (var i = 1; i <= 3; i++) 'diag_${d}_$i',
  ];
  return DestinyMatrixReading(
    birthDate: '2003-10-02',
    points: [for (final k in keys) _pt(k, v)],
    lines: const [],
    ageLadder: [
      for (var d = 0; d < 8; d++) ...[
        AgeArcana(age: d * 10.0, label: '${d * 10}', arcana: v),
        for (var i = 1; i <= 7; i++)
          AgeArcana(
            age: d * 10 + 1.25 * i,
            label: (d * 10 + 1.25 * i).toStringAsFixed(2),
            arcana: v,
          ),
      ],
    ],
  );
}
