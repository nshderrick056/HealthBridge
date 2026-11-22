
import 'dart:convert';

import '../core/widgets/widgets.dart';
import '../data/db.dart';
import '../data/models.dart';

String visitTypeLabel(VisitType type) => switch (type) {
  VisitType.maternal => 'Maternal Health',
  VisitType.child => 'Child Health',
  VisitType.malaria => 'Malaria',
  VisitType.nutrition => 'Malnutrition',
};

const months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String two(int number) => number.toString().padLeft(2, '0');

String dayMonth(DateTime date) =>
    '${date.day} ${months[date.month - 1]}';

String fullDate(DateTime date) =>
    '${date.day} ${months[date.month - 1]} ${date.year}';

String clock(DateTime date) =>
    '${two(date.hour)}:${two(date.minute)}';

bool sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String relativeDay(DateTime date, [DateTime? now]) {
  final today = (now ?? DateTime.now()).toLocal();
  final target = date.toLocal();

  if (sameDay(target, today)) return 'Today';

  final yesterday = DateTime(
    today.year,
    today.month,
    today.day - 1,
  );

  if (sameDay(target, yesterday)) return 'Yesterday';

  return dayMonth(target);
}

const needsAttention = 'Needs attention';

class PatientView {
  PatientView(this.patient, List<Visit> visits)
      : visits = List<Visit>.of(visits)
          ..sort(
            (a, b) => b.recordedAt.compareTo(a.recordedAt),
          );

  final Patient patient;
  final List<Visit> visits;

  Visit? get latest =>
      visits.isEmpty ? null : visits.first;

  StatusKind get status {
    final visit = latest;

    if (visit == null) return StatusKind.stable;

    if (visit.isUrgent) return StatusKind.urgent;

    try {
      final answers = jsonDecode(visit.answersJson);

      if (answers is Map &&
          answers['general_condition'] == needsAttention) {
        return StatusKind.attention;
      }
    } on FormatException {
      // Invalid answers should not prevent displaying the patient.
    }

    final followUp = visit.followUpOn;

    if (followUp != null &&
        !followUp.isAfter(DateTime.now())) {
      return StatusKind.followUp;
    }

    return StatusKind.stable;
  }

  String get ageSex {
    final birthDate = patient.birthDate;
    int? age = patient.ageEstimate;

    if (birthDate != null) {
      final today = DateTime.now();

      age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month &&
              today.day < birthDate.day)) {
        age--;
      }
    }

    final sex = switch (patient.sex) {
      'F' => 'Female',
      'M' => 'Male',
      _ => null,
    };

    return [
      if (age != null && age >= 0) '$age years',
      if (sex != null) sex,
    ].join(' · ');
  }

  String get when {
    final visit = latest;

    return visit == null
        ? 'No visits'
        : relativeDay(visit.recordedAt);
  }
}

List<PatientView> buildPatientViews(
  List<Patient> patients,
  List<Visit> visits,
) {
  final visitsByPatient = <String, List<Visit>>{};

  for (final visit in visits) {
    visitsByPatient
        .putIfAbsent(visit.patientId, () => <Visit>[])
        .add(visit);
  }

  return [
    for (final patient in patients)
      PatientView(
        patient,
        visitsByPatient[patient.id] ?? const <Visit>[],
      ),
  ];
}

class SyncCounts {
  const SyncCounts({
    required this.synced,
    required this.pending,
    required this.failed,
  });

  final int synced;
  final int pending;
  final int failed;
}

SyncCounts syncCounts(
  List<Patient> patients,
  List<Visit> visits,
) {
  var synced = 0;
  var pending = 0;
  var failed = 0;

  final states = [
    ...patients.map((patient) => patient.syncState),
    ...visits.map((visit) => visit.syncState),
  ];

  for (final state in states) {
    switch (state) {
      case SyncState.synced:
        synced++;
      case SyncState.local:
      case SyncState.queued:
        pending++;
      case SyncState.failed:
        failed++;
    }
  }

  return SyncCounts(
    synced: synced,
    pending: pending,
    failed: failed,
  );
}
