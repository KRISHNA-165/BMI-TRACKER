import 'package:flutter_test/flutter_test.dart';
import 'package:bmi_tracker/utils/bmi_calculator.dart';

void main() {
  group('BmiCalculator - Formula & Unit Conversions', () {
    test('calculateBmi returns correct rounded value for metric units', () {
      // 70 kg, 175 cm -> 70 / (1.75 * 1.75) = 22.857... -> 22.9
      final bmi = BmiCalculator.calculateBmi(weightKg: 70.0, heightCm: 175.0);
      expect(bmi, 22.9);
    });

    test('calculateBmi returns 0 for non-positive inputs', () {
      expect(BmiCalculator.calculateBmi(weightKg: 0, heightCm: 170), 0.0);
      expect(BmiCalculator.calculateBmi(weightKg: 70, heightCm: 0), 0.0);
    });

    test('lbsToKg and kgToLbs convert accurately', () {
      const lbs = 154.32;
      final kg = BmiCalculator.lbsToKg(lbs);
      expect(kg, closeTo(70.0, 0.1));

      final convertedBackLbs = BmiCalculator.kgToLbs(kg);
      expect(convertedBackLbs, closeTo(lbs, 0.001));
    });

    test('ftInToCm and cmToFtIn convert accurately', () {
      // 5 feet 9 inches = 69 inches = 175.26 cm
      final cm = BmiCalculator.ftInToCm(5, 9);
      expect(cm, closeTo(175.26, 0.01));

      final (feet, inches) = BmiCalculator.cmToFtIn(cm);
      expect(feet, 5);
      expect(inches, 9);
    });
  });

  group('BmiCalculator - PRD Categories and Edge Values', () {
    test('Underweight category for BMI < 18.5', () {
      expect(BmiCalculator.getCategory(18.4), 'Underweight');
      expect(BmiCalculator.getCategory(15.0), 'Underweight');
    });

    test('Normal weight category for BMI 18.5 - 24.9', () {
      expect(BmiCalculator.getCategory(18.5), 'Normal weight'); // Edge value
      expect(BmiCalculator.getCategory(22.0), 'Normal weight');
      expect(BmiCalculator.getCategory(24.9), 'Normal weight'); // Edge value
    });

    test('Overweight category for BMI 25.0 - 29.9', () {
      expect(BmiCalculator.getCategory(25.0), 'Overweight'); // Edge value
      expect(BmiCalculator.getCategory(27.5), 'Overweight');
      expect(BmiCalculator.getCategory(29.9), 'Overweight'); // Edge value
    });

    test('Obese category for BMI >= 30.0', () {
      expect(BmiCalculator.getCategory(30.0), 'Obese'); // Edge value
      expect(BmiCalculator.getCategory(35.2), 'Obese');
    });
  });
}
