
import '../../data/db.dart';
import '../../data/models.dart';

class VisitForm {
  VisitForm({
    required this.patient,
    this.type = VisitType.maternal,
    this.symptoms = '',
    this.temperature,
    this.condition = 'Stable',
    this.notes = '',
    Set<String>? signs,
    this.followUpOn,
  }) : signs = signs ?? <String>{};

  final Patient patient;

  VisitType type;
  String symptoms;
  double? temperature;
  String condition;
  String notes;
  Set<String> signs;
  DateTime? followUpOn;

  Map<String, Object?> toDraft() {
    return {
      'type': type.name,
      'symptoms': symptoms,
      'temperature': temperature,
      'condition': condition,
      'notes': notes,
      'signs': signs.toList(),
      if (followUpOn != null)
        'followUpOn': followUpOn!.toIso8601String(),
    };
  }

  void restore(Map<String, Object?> draft) {
    final savedType = draft['type'];

    if (savedType is String) {
      type = VisitType.values.asNameMap()[savedType] ?? type;
    }

    final savedSymptoms = draft['symptoms'];
    symptoms = savedSymptoms is String ? savedSymptoms : '';

    final savedTemperature = draft['temperature'];

    if (savedTemperature is num) {
      temperature = savedTemperature.toDouble();
    } else if (savedTemperature is String) {
      temperature = double.tryParse(savedTemperature.trim());
    } else {
      temperature = null;
    }

    final savedCondition = draft['condition'];
    condition = savedCondition is String
        ? savedCondition
        : 'Stable';

    final savedNotes = draft['notes'];
    notes = savedNotes is String ? savedNotes : '';

    final savedSigns = draft['signs'];
    signs = savedSigns is List
        ? savedSigns.whereType<String>().toSet()
        : <String>{};

    final savedFollowUp = draft['followUpOn'];

    followUpOn = savedFollowUp is String
        ? DateTime.tryParse(savedFollowUp)
        : null;
  }

  Map<String, Object?> get answers {
    return {
      'symptoms': symptoms,
      if (temperature != null)
        'temperature': temperature,
      'general_condition': condition,
    };
  }
}
