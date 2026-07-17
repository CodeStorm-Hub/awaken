import 'package:awaken/features/alarm/domain/services/next_alarm_occurrence.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextAlarmOccurrence', () {
    test('schedules later today when the picked time is still ahead', () {
      // Regression: picking a time ~1 minute out used to be pushed a full
      // day ahead because the old check compared against `now + 1 minute`
      // instead of `now` — since TimeOfDay has no seconds, `scheduled`
      // (:00 seconds) was almost always "before" that inflated threshold.
      final now = DateTime(2026, 7, 17, 6, 40, 30);
      final result = nextAlarmOccurrence(const TimeOfDay(hour: 6, minute: 41), now);

      expect(result, DateTime(2026, 7, 17, 6, 41));
    });

    test('schedules tomorrow when the picked time has already passed today', () {
      final now = DateTime(2026, 7, 17, 6, 41, 30);
      final result = nextAlarmOccurrence(const TimeOfDay(hour: 6, minute: 41), now);

      expect(result, DateTime(2026, 7, 18, 6, 41));
    });

    test('schedules tomorrow when the picked time equals the current minute', () {
      final now = DateTime(2026, 7, 17, 6, 41, 0);
      final result = nextAlarmOccurrence(const TimeOfDay(hour: 6, minute: 41), now);

      expect(result, DateTime(2026, 7, 18, 6, 41));
    });

    test('handles a time many hours ahead later today', () {
      final now = DateTime(2026, 7, 17, 6, 40);
      final result = nextAlarmOccurrence(const TimeOfDay(hour: 22, minute: 0), now);

      expect(result, DateTime(2026, 7, 17, 22));
    });
  });
}
