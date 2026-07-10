import 'package:flutter/foundation.dart';

/// A territory the current user owns that is within the decay grace period
/// and will start shrinking soon unless they run through it again.
@immutable
class DecayWarningEntity {
  const DecayWarningEntity({
    required this.territoryId,
    required this.daysUntilDecay,
    required this.areaSqMeters,
  });

  final String territoryId;
  final double daysUntilDecay;
  final double areaSqMeters;
}
