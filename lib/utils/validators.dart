import 'package:intl/intl.dart';

class Validators {
  static const int minAgeYears = 1;
  static const int maxAgeYears = 120;
  static const double minWeightKg = 20.0;
  static const double maxWeightKg = 300.0;
  static const double minHeightCm = 90.0;
  static const double maxHeightCm = 250.0;

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&'
      r"'"
      r'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validate password strength: min 8 chars, at least 1 number
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least 1 number';
    }
    return null;
  }

  /// Validate password confirmation
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate profile name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validate weight (kg or lbs)
  static String? validateWeight(String? value, {bool isLbs = false}) {
    if (value == null || value.trim().isEmpty) {
      return 'Weight is required';
    }
    final weight = double.tryParse(value.trim());
    if (weight == null) {
      return 'Enter a valid number for weight';
    }

    final weightKg = isLbs ? weight * 0.453592 : weight;
    if (weightKg < minWeightKg || weightKg > maxWeightKg) {
      final minDisp = isLbs ? (minWeightKg / 0.453592).round() : minWeightKg.toInt();
      final maxDisp = isLbs ? (maxWeightKg / 0.453592).round() : maxWeightKg.toInt();
      final unit = isLbs ? 'lbs' : 'kg';
      return 'Weight must be between $minDisp and $maxDisp $unit';
    }
    return null;
  }

  /// Validate height (cm)
  static String? validateHeightCm(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Height is required';
    }
    final height = double.tryParse(value.trim());
    if (height == null) {
      return 'Enter a valid number for height';
    }
    if (height < minHeightCm || height > maxHeightCm) {
      return 'Height must be between ${minHeightCm.toInt()} and ${maxHeightCm.toInt()} cm';
    }
    return null;
  }

  /// Validate Feet input (range 2–8 ft)
  static String? validateFeet(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    final feet = int.tryParse(value.trim());
    if (feet == null || feet < 2 || feet > 8) {
      return '2-8 ft';
    }
    return null;
  }

  /// Validate Inches input (range 0–11 in)
  static String? validateInches(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    final inches = int.tryParse(value.trim());
    if (inches == null || inches < 0 || inches > 11) {
      return '0-11 in';
    }
    return null;
  }

  /// Validate Date of Birth (DOB)
  static String? validateDob(DateTime? dob) {
    if (dob == null) {
      return 'Date of birth is required';
    }
    final now = DateTime.now();
    if (dob.isAfter(now)) {
      return 'Date of birth cannot be in the future';
    }

    final age = calculateAge(dob);
    if (age < minAgeYears || age > maxAgeYears) {
      return 'Age must be between $minAgeYears and $maxAgeYears years';
    }
    return null;
  }

  /// Calculate exact age in years
  static int calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  /// Format date for display (e.g. "15 Aug 1995")
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
}
