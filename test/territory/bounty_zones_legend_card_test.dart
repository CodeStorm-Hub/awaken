import 'package:awaken/core/theme/app_theme.dart';
import 'package:awaken/features/territory/domain/entities/bounty_zone_entity.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:awaken/features/territory/presentation/widgets/bounty_zones_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testZone = BountyZoneEntity(
    id: '1',
    label: 'SHER-E-BANGLA STADIUM',
    multiplier: 3.0,
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    ring: [
      GeoPointEntity(
        latitude: 40.0,
        longitude: -74.0,
        timestamp: DateTime.now(),
      ),
      GeoPointEntity(
        latitude: 40.1,
        longitude: -74.0,
        timestamp: DateTime.now(),
      ),
      GeoPointEntity(
        latitude: 40.1,
        longitude: -74.1,
        timestamp: DateTime.now(),
      ),
    ],
  );

  testWidgets(
    'BountyZonesLegendCard renders when visible and not dismissed, hides on close tap',
    (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          bountyZonesProvider.overrideWith((ref) => [testZone]),
          bountyZonesVisibleProvider.overrideWith((ref) => true),
          bountyZonesHintDismissedProvider.overrideWith((ref) => false),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(body: BountyZonesLegendCard()),
          ),
        ),
      );

      // Verify it is visible
      expect(find.text('BOUNTY ZONES'), findsOneWidget);
      expect(find.text('3× · SHER-E-BANGLA STADIUM'), findsOneWidget);

      // Tap the close button
      final closeButton = find.byIcon(Icons.close_rounded);
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Verify it is now dismissed and returns SizedBox.shrink()
      expect(container.read(bountyZonesHintDismissedProvider), isTrue);
      expect(find.text('BOUNTY ZONES'), findsNothing);
    },
  );
}
