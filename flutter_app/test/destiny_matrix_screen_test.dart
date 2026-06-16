import 'package:cosmic_mirror/config/theme/app_theme.dart';
import 'package:cosmic_mirror/features/destiny_matrix/domain/entities/destiny_matrix.dart';
import 'package:cosmic_mirror/features/destiny_matrix/presentation/providers/destiny_matrix_providers.dart';
import 'package:cosmic_mirror/features/destiny_matrix/presentation/screens/destiny_matrix_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/destiny_matrix_fixture.dart';

// Drives the real DestinyMatrixScreen / octagram board with mock readings to
// confirm the graph renders, interacts, and never overflows. The screen's
// LivelyBackdrop repeats forever, so we pump fixed durations (never settle).

Widget _screen(DestinyMatrixReading reading) => ProviderScope(
      overrides: [
        destinyMatrixReadingProvider.overrideWith((ref) async => reading),
      ],
      child: MaterialApp(
        theme: CosmicTheme.darkTheme,
        home: const DestinyMatrixScreen(),
      ),
    );

Future<void> _settleData(WidgetTester tester) async {
  await tester.pump(); // resolve the (already-complete) future provider
  await tester.pump(const Duration(milliseconds: 600)); // fade-ins
}

void main() {
  testWidgets('renders the screen + octagram with no overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_screen(referenceReading()));
    await _settleData(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Matrix of Destiny'), findsOneWidget);
    // Hero core arcana + octagram are present.
    expect(find.text('7'), findsWidgets);
    expect(find.text('Your Octagram'), findsOneWidget);
  });

  testWidgets('tapping the centre node opens its arcana sheet', (tester) async {
    const side = 380.0;
    await tester.binding.setSurfaceSize(const Size(side, side));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: CosmicTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              key: const Key('board'),
              width: side,
              height: side,
              child: debugOctagramBoard(
                referenceReading(),
                const Size(side, side),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // The centre (gold) node sits exactly at the board centre.
    await tester.tapAt(tester.getCenter(find.byKey(const Key('board'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The detail sheet shows the centre point's title + arcana name.
    expect(find.text('Comfort / Core'), findsOneWidget);
    expect(find.text('Arcana 7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full-screen button opens the zoomable view', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_screen(referenceReading()));
    await _settleData(tester);

    await tester.tap(find.byTooltip('Full screen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Pinch to resize'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('worst-case all-22 values never overflow a node', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_screen(uniformReading(22)));
    await _settleData(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('22'), findsWidgets);
  });
}
