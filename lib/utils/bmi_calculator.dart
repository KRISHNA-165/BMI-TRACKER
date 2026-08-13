import 'package:flutter/material.dart';

class BmiCategory {
  final String label;
  final Color color;
  final Color backgroundColor;
  final String description;

  const BmiCategory({
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.description,
  });
}

class BmiCalculator {
  static const double lbsToKgMultiplier = 0.453592;
  static const double inchesToMetersMultiplier = 0.0254;

  /// Convert pounds (lbs) to kilograms (kg)
  static double lbsToKg(double lbs) {
    return lbs * lbsToKgMultiplier;
  }

  /// Convert kilograms (kg) to pounds (lbs)
  static double kgToLbs(double kg) {
    return kg / lbsToKgMultiplier;
  }

  /// Convert feet and inches to centimeters
  static double ftInToCm(int feet, int inches) {
    final totalInches = (feet * 12) + inches;
    return totalInches * 2.54;
  }

  /// Convert centimeters to feet and inches tuple (feet, inches)
  static (int feet, int inches) cmToFtIn(double cm) {
    final totalInches = (cm / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return (feet, inches);
  }

  /// Convert height in cm to meters
  static double cmToMeters(double cm) {
    return cm / 100.0;
  }

  /// Calculate BMI value given weight in KG and height in CM.
  /// Result is rounded to 1 decimal place.
  static double calculateBmi({
    required double weightKg,
    required double heightCm,
  }) {
    if (heightCm <= 0 || weightKg <= 0) return 0.0;
    final heightMeters = cmToMeters(heightCm);
    final bmi = weightKg / (heightMeters * heightMeters);
    return double.parse(bmi.toStringAsFixed(1));
  }

  /// Get BMI Category String per PRD spec:
  /// < 18.5      -> Underweight
  /// 18.5 - 24.9 -> Normal weight
  /// 25.0 - 29.9 -> Overweight
  /// >= 30.0     -> Obese
  static String getCategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi <= 24.9) {
      return 'Normal weight';
    } else if (bmi <= 29.9) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }

  /// Get rich category design data (colors and descriptions)
  static BmiCategory getCategoryDetails(double bmi) {
    final cat = getCategory(bmi);
    switch (cat) {
      case 'Underweight':
        return const BmiCategory(
          label: 'Underweight',
          color: Color(0xFF38BDF8), // Cyan / Light Blue
          backgroundColor: Color(0x2038BDF8),
          description: 'Your BMI indicates you are below the normal weight range. Consider consulting a healthcare professional.',
        );
      case 'Normal weight':
        return const BmiCategory(
          label: 'Normal weight',
          color: Color(0xFF22C55E), // Emerald Green
          backgroundColor: Color(0x2022C55E),
          description: 'Great job! Your BMI is within the healthy weight range.',
        );
      case 'Overweight':
        return const BmiCategory(
          label: 'Overweight',
          color: Color(0xFFF97316), // Orange
          backgroundColor: Color(0x20F97316),
          description: 'Your BMI is slightly above the normal range. Regular exercise and balanced nutrition can help.',
        );
      case 'Obese':
      default:
        return const BmiCategory(
          label: 'Obese',
          color: Color(0xFFEF4444), // Coral Red
          backgroundColor: Color(0x20EF4444),
          description: 'Your BMI indicates obesity. We recommend discussing healthy lifestyle plans with a physician.',
        );
    }
  }
}
