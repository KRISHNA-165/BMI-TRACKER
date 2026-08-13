import 'package:cloud_firestore/cloud_firestore.dart';

class WeightEntry {
  final String id;
  final double weightKg;
  final DateTime loggedAt;

  const WeightEntry({
    required this.id,
    required this.weightKg,
    required this.loggedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weightKg': weightKg,
      'loggedAt': Timestamp.fromDate(loggedAt),
    };
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'weightKg': weightKg,
      'loggedAt': loggedAt.toIso8601String(),
    };
  }

  factory WeightEntry.fromMap(String docId, Map<String, dynamic> map) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) {
        return date.toDate();
      } else if (date is String) {
        return DateTime.tryParse(date) ?? DateTime.now();
      } else if (date is int) {
        return DateTime.fromMillisecondsSinceEpoch(date);
      }
      return DateTime.now();
    }

    final id = (map['id'] as String?) ?? docId;

    return WeightEntry(
      id: id,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
      loggedAt: parseDate(map['loggedAt']),
    );
  }

  WeightEntry copyWith({
    String? id,
    double? weightKg,
    DateTime? loggedAt,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      weightKg: weightKg ?? this.weightKg,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }
}
