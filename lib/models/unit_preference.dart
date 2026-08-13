enum HeightUnit {
  cm('cm', 'Centimeters'),
  ftIn('ft', 'Feet & Inches');

  final String code;
  final String label;

  const HeightUnit(this.code, this.label);

  static HeightUnit fromString(String? value) {
    if (value == 'ft' || value == 'ftIn' || value == 'ft_in') {
      return HeightUnit.ftIn;
    }
    return HeightUnit.cm;
  }
}

enum WeightUnit {
  kg('kg', 'Kilograms (kg)'),
  lbs('lbs', 'Pounds (lbs)');

  final String code;
  final String label;

  const WeightUnit(this.code, this.label);

  static WeightUnit fromString(String? value) {
    if (value == 'lbs' || value == 'lb') {
      return WeightUnit.lbs;
    }
    return WeightUnit.kg;
  }
}

class UnitPreference {
  final HeightUnit heightUnit;
  final WeightUnit weightUnit;

  const UnitPreference({
    this.heightUnit = HeightUnit.cm,
    this.weightUnit = WeightUnit.kg,
  });

  Map<String, dynamic> toMap() {
    return {
      'height': heightUnit.code,
      'weight': weightUnit.code,
    };
  }

  factory UnitPreference.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UnitPreference();
    return UnitPreference(
      heightUnit: HeightUnit.fromString(map['height'] as String?),
      weightUnit: WeightUnit.fromString(map['weight'] as String?),
    );
  }

  UnitPreference copyWith({
    HeightUnit? heightUnit,
    WeightUnit? weightUnit,
  }) {
    return UnitPreference(
      heightUnit: heightUnit ?? this.heightUnit,
      weightUnit: weightUnit ?? this.weightUnit,
    );
  }
}
