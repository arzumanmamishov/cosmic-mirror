import 'package:cosmic_mirror/features/destiny_matrix/domain/entities/destiny_matrix.dart';
import 'package:cosmic_mirror/features/destiny_matrix/presentation/screens/destiny_matrix_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Renders the octagram board with the SAME example birth date the reference
// chart uses (Day->2, Month->10, Year->5) so the golden can be compared
// directly against the reference image. The values below are produced by the
// authentic backend algorithm, mirrored here so the test is self-contained.
// ---------------------------------------------------------------------------

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

DestinyPoint _pt(String key, int arcana) => DestinyPoint(
      key: key,
      position: key,
      title: key,
      arcana: arcana,
      arcanaName: '',
      meaning: '',
    );

DestinyMatrixReading _referenceReading() {
  // Reduced birth-date inputs that reproduce the reference chart.
  const day = 2;
  const month = 10;
  const year = 5;
  final sum = _reduce(day + month + year); // 17
  final center = _reduce(day + month + year + sum); // 7

  final tl = _reduce(day + month); // 12
  final tr = _reduce(month + year); // 15
  final br = _reduce(year + sum); // 22
  final bl = _reduce(sum + day); // 19

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
    _pt('day', day), _pt('month', month), _pt('year', year), _pt('sum', sum),
    _pt('tl', tl), _pt('tr', tr), _pt('br', br), _pt('bl', bl),
    _pt('center', center),
    _pt('heaven', heaven), _pt('earth', earth), _pt('personal', personal),
    _pt('arm_left_1', left[0]), _pt('arm_left_2', left[1]),
    _pt('arm_left_3', left[2]),
    _pt('arm_top_1', top[0]), _pt('arm_top_2', top[1]), _pt('arm_top_3', top[2]),
    _pt('arm_right_1', right[0]), _pt('arm_right_2', right[1]),
    _pt('arm_right_3', right[2]),
    _pt('arm_bottom_1', bottom[0]), _pt('arm_bottom_2', bottom[1]),
    _pt('arm_bottom_3', bottom[2]),
    _pt('diag_tl_1', dtl[0]), _pt('diag_tl_2', dtl[1]), _pt('diag_tl_3', dtl[2]),
    _pt('diag_tr_1', dtr[0]), _pt('diag_tr_2', dtr[1]), _pt('diag_tr_3', dtr[2]),
    _pt('diag_br_1', dbr[0]), _pt('diag_br_2', dbr[1]), _pt('diag_br_3', dbr[2]),
    _pt('diag_bl_1', dbl[0]), _pt('diag_bl_2', dbl[1]), _pt('diag_bl_3', dbl[2]),
  ];

  // Perimeter age ladder: 8 corners (clockwise from Day at age 0) + 7 ticks per
  // edge via 3-level binary subdivision.
  final corners = [day, tl, month, tr, year, br, sum, bl];
  final ladder = <AgeArcana>[];
  for (var d = 0; d < 8; d++) {
    final startAge = d * 10.0;
    final v0 = corners[d];
    final v8 = corners[(d + 1) % 8];
    ladder.add(AgeArcana(age: startAge, label: '${startAge.toInt()}', arcana: v0));
    final v4 = _reduce(v0 + v8);
    final v2 = _reduce(v0 + v4);
    final v6 = _reduce(v4 + v8);
    final ticks = [
      _reduce(v0 + v2), v2, _reduce(v2 + v4), v4, _reduce(v4 + v6), v6,
      _reduce(v6 + v8),
    ];
    for (var i = 0; i < ticks.length; i++) {
      final age = startAge + 1.25 * (i + 1);
      ladder.add(AgeArcana(age: age, label: age.toStringAsFixed(2), arcana: ticks[i]));
    }
  }

  return DestinyMatrixReading(
    birthDate: '2003-10-02',
    points: points,
    lines: const [],
    ageLadder: ladder,
  );
}

Future<void> _pumpBoard(WidgetTester tester, double side) async {
  await tester.binding.setSurfaceSize(Size(side, side));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF14101F),
        body: Center(
          child: RepaintBoundary(
            child: SizedBox(
              width: side,
              height: side,
              child: debugOctagramBoard(_referenceReading(), Size(side, side)),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  // Render at a realistic in-card phone size: the node radii use absolute-px
  // clamps, so layout must be verified at the size users actually see.
  testWidgets('octagram board golden — phone card', (tester) async {
    await _pumpBoard(tester, 380);
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/octagram_reference.png'),
    );
  });

  // Render at the full-screen / pinch-zoom size to verify the layout scales up.
  testWidgets('octagram board golden — full screen', (tester) async {
    await _pumpBoard(tester, 820);
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/octagram_reference_large.png'),
    );
  });
}
