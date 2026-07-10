import 'package:awaken/features/territory/domain/entities/decay_warning_entity.dart';

class DecayWarningModel {
  const DecayWarningModel({
    required this.id,
    required this.daysUntilDecay,
    required this.areaSqMeters,
  });

  factory DecayWarningModel.fromJson(Map<String, dynamic> json) {
    return DecayWarningModel(
      id: json['id'] as String,
      daysUntilDecay: (json['days_until_decay'] as num).toDouble(),
      areaSqMeters: (json['area_sqm'] as num).toDouble(),
    );
  }

  final String id;
  final double daysUntilDecay;
  final double areaSqMeters;

  DecayWarningEntity toEntity() {
    return DecayWarningEntity(
      territoryId: id,
      daysUntilDecay: daysUntilDecay,
      areaSqMeters: areaSqMeters,
    );
  }
}
