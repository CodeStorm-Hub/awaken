import 'package:flutter/material.dart' show TimeOfDay;

/// Resolves the next wall-clock occurrence of [time] relative to [now]:
/// today if [time] hasn't passed yet, otherwise tomorrow.
///
/// A single shared implementation — this used to be duplicated between the
/// setup screen's countdown label and its actual save/schedule path, and the
/// two copies drifted apart (the save path additionally compared against
/// `now + 1 minute` instead of `now`). Since [TimeOfDay] has no seconds
/// component, `scheduled` always lands on `:00` seconds while `now` carries
/// its own seconds — so `scheduled.isBefore(now + 1 minute)` was true for
/// almost any `now`, silently pushing the alarm a full day out even when the
/// picked time was still clearly ahead of the current time.
DateTime nextAlarmOccurrence(TimeOfDay time, DateTime now) {
  var scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
  if (!scheduled.isAfter(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}
