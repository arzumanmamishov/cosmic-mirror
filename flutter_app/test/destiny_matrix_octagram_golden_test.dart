import 'package:cosmic_mirror/features/destiny_matrix/presentation/screens/destiny_matrix_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/destiny_matrix_fixture.dart';

// Renders the octagram board with the SAME example birth date as the reference
// chart (Day->2, Month->10, Year->5; see referenceReading) so the golden can be
// compared directly against the reference image. Values come from the authentic
// backend algorithm, mirrored in the shared fixture.

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
              child: debugOctagramBoard(referenceReading(), Size(side, side)),
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
