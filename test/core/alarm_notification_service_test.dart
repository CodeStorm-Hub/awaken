import 'package:awaken/core/services/alarm_notification_service.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlarmNotificationService', () {
    test('two alarms same second get different notification IDs', () {
      final scheduled = DateTime(2026, 7, 3, 7, 0, 0);
      final alarmA = AlarmEntity(
        id: 'alarm-a',
        scheduledTime: scheduled,
        requiredReps: 10,
        isActive: true,
      );
      final alarmB = AlarmEntity(
        id: 'alarm-b',
        scheduledTime: scheduled,
        requiredReps: 10,
        isActive: true,
      );

      expect(
        AlarmNotificationService.notificationIdFor(alarmA),
        isNot(equals(AlarmNotificationService.notificationIdFor(alarmB))),
      );
    });

    test('payload round-trip preserves id, reps, scheduledTime', () {
      final scheduled = DateTime(2026, 7, 3, 7, 30, 45);
      final alarm = AlarmEntity(
        id: 'test-id',
        scheduledTime: scheduled,
        requiredReps: 15,
        isActive: true,
      );

      final payload = AlarmNotificationService.buildPayload(alarm);
      final parsed = AlarmNotificationService.parsePayload(payload);

      expect(parsed, isNotNull);
      expect(parsed!.id, 'test-id');
      expect(parsed.reps, 15);
      expect(parsed.scheduledTime, scheduled);
    });

    test('buildActiveRouteFromPayload includes scheduled param', () {
      final scheduled = DateTime(2026, 7, 3, 7, 30, 45);
      final payload = 'abc|10|${scheduled.toIso8601String()}';

      final route = AlarmNotificationService.buildActiveRouteFromPayload(
        payload,
      );

      expect(route, contains('id=abc'));
      expect(route, contains('reps=10'));
      expect(
        route,
        contains(
          'scheduled=${Uri.encodeComponent(scheduled.toIso8601String())}',
        ),
      );
    });
  });
}
