import 'package:flutter_test/flutter_test.dart';
import 'package:bmi_tracker/utils/validators.dart';

void main() {
  group('Validators - Email & Password', () {
    test('validateEmail validates proper email addresses', () {
      expect(Validators.validateEmail('test@example.com'), null);
      expect(Validators.validateEmail('user.name+tag@domain.co.in'), null);
      expect(Validators.validateEmail('invalid-email'), 'Enter a valid email address');
      expect(Validators.validateEmail(''), 'Email address is required');
    });

    test('validatePassword validates length and number requirement', () {
      expect(Validators.validatePassword('Password123'), null);
      expect(Validators.validatePassword('short1'), 'Password must be at least 8 characters');
      expect(Validators.validatePassword('NoNumbersHere'), 'Password must contain at least 1 number');
    });

    test('validateConfirmPassword checks match', () {
      expect(Validators.validateConfirmPassword('Password123', 'Password123'), null);
      expect(Validators.validateConfirmPassword('Password123', 'Password456'), 'Passwords do not match');
    });
  });

  group('Validators - Weight & Height Ranges', () {
    test('validateWeight enforces 20-300 kg boundaries', () {
      expect(Validators.validateWeight('70'), null);
      expect(Validators.validateWeight('19'), isNotNull); // < 20 kg
      expect(Validators.validateWeight('301'), isNotNull); // > 300 kg
      expect(Validators.validateWeight('abc'), 'Enter a valid number for weight');
    });

    test('validateHeightCm enforces 90-250 cm boundaries', () {
      expect(Validators.validateHeightCm('170'), null);
      expect(Validators.validateHeightCm('89'), isNotNull);
      expect(Validators.validateHeightCm('251'), isNotNull);
    });

    test('validateDob enforces past date and age range 1-120 years', () {
      final now = DateTime.now();
      final validDob = DateTime(now.year - 25, 5, 10);
      expect(Validators.validateDob(validDob), null);

      final futureDob = DateTime(now.year + 1, 1, 1);
      expect(Validators.validateDob(futureDob), 'Date of birth cannot be in the future');

      final tooOldDob = DateTime(now.year - 125, 1, 1);
      expect(Validators.validateDob(tooOldDob), isNotNull);
    });
  });
}
