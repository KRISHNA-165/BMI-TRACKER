import 'package:cloud_firestore/cloud_firestore.dart';
import 'unit_preference.dart';

class UserProfile {
  final String id;
  final String name;
  final String gender;
  final DateTime dob;
  final double heightCm;
  final double weightKg;
  final UnitPreference unitPreference;
  final double currentBmi;
  final String bmiCategory;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.gender,
    required this.dob,
    required this.heightCm,
    required this.weightKg,
    this.unitPreference = const UnitPreference(),
    required this.currentBmi,
    required this.bmiCategory,
    required this.updatedAt,
  });

  /// Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'dob': Timestamp.fromDate(dob),
      'heightCm': heightCm,
      'weightKg': weightKg,
      'unitPreference': unitPreference.toMap(),
      'currentBmi': currentBmi,
      'bmiCategory': bmiCategory,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Map for JSON / SharedPreferences local storage (no Timestamp objects)
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'dob': dob.toIso8601String(),
      'heightCm': heightCm,
      'weightKg': weightKg,
      'unitPreference': unitPreference.toMap(),
      'currentBmi': currentBmi,
      'bmiCategory': bmiCategory,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(String docId, Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    final id = (map['id'] as String?) ?? docId;

    return UserProfile(
      id: id,
      name: map['name'] as String? ?? 'User',
      gender: map['gender'] as String? ?? 'Male',
      dob: parseDate(map['dob']),
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 170.0,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 70.0,
      unitPreference: UnitPreference.fromMap(
        map['unitPreference'] as Map<String, dynamic>?,
      ),
      currentBmi: (map['currentBmi'] as num?)?.toDouble() ?? 0.0,
      bmiCategory: map['bmiCategory'] as String? ?? 'Normal weight',
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? gender,
    DateTime? dob,
    double? heightCm,
    double? weightKg,
    UnitPreference? unitPreference,
    double? currentBmi,
    String? bmiCategory,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      unitPreference: unitPreference ?? this.unitPreference,
      currentBmi: currentBmi ?? this.currentBmi,
      bmiCategory: bmiCategory ?? this.bmiCategory,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
