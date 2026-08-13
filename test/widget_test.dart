import 'package:flutter_test/flutter_test.dart';
import 'package:bmi_tracker/utils/bmi_calculator.dart';

void main() {
  test('BMI Calculator smoke test', () {
    final bmi = BmiCalculator.calculateBmi(weightKg: 70, heightCm: 170);
    expect(bmi, greaterThan(0));
  });
}
