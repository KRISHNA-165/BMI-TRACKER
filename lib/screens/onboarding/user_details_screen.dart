import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/unit_preference.dart';
import '../../providers/profile_provider.dart';
import '../../utils/bmi_calculator.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/bmi_badge.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/unit_toggle_button.dart';

class UserDetailsScreen extends ConsumerStatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  ConsumerState<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends ConsumerState<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: 'Self');
  final _weightController = TextEditingController(text: '70');
  final _heightController = TextEditingController(text: '170');
  final _feetController = TextEditingController(text: '5');
  final _inchesController = TextEditingController(text: '7');

  HeightUnit _heightUnit = HeightUnit.cm;
  WeightUnit _weightUnit = WeightUnit.kg;
  String _gender = 'Male';
  DateTime? _dob = DateTime.now().subtract(const Duration(days: 365 * 25)); // Default age 25

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  /// Convert height unit without data loss
  void _onHeightUnitChanged(HeightUnit newUnit) {
    if (_heightUnit == newUnit) return;

    if (newUnit == HeightUnit.ftIn) {
      // Convert CM to Ft & In
      final currentCm = double.tryParse(_heightController.text) ?? 170.0;
      final (feet, inches) = BmiCalculator.cmToFtIn(currentCm);
      _feetController.text = feet.toString();
      _inchesController.text = inches.toString();
    } else {
      // Convert Ft & In to CM
      final ft = int.tryParse(_feetController.text) ?? 5;
      final inch = int.tryParse(_inchesController.text) ?? 7;
      final cm = BmiCalculator.ftInToCm(ft, inch);
      _heightController.text = cm.toStringAsFixed(0);
    }

    setState(() {
      _heightUnit = newUnit;
    });
  }

  /// Convert weight unit without data loss
  void _onWeightUnitChanged(WeightUnit newUnit) {
    if (_weightUnit == newUnit) return;

    final currentWeight = double.tryParse(_weightController.text) ?? 70.0;
    if (newUnit == WeightUnit.lbs) {
      // KG -> LBS
      final lbs = BmiCalculator.kgToLbs(currentWeight);
      _weightController.text = lbs.toStringAsFixed(1);
    } else {
      // LBS -> KG
      final kg = BmiCalculator.lbsToKg(currentWeight);
      _weightController.text = kg.toStringAsFixed(1);
    }

    setState(() {
      _weightUnit = newUnit;
    });
  }

  /// Get height in CM regardless of selected unit
  double _getCalculatedHeightCm() {
    if (_heightUnit == HeightUnit.cm) {
      return double.tryParse(_heightController.text) ?? 170.0;
    } else {
      final ft = int.tryParse(_feetController.text) ?? 5;
      final inch = int.tryParse(_inchesController.text) ?? 7;
      return BmiCalculator.ftInToCm(ft, inch);
    }
  }

  /// Get weight in KG regardless of selected unit
  double _getCalculatedWeightKg() {
    final val = double.tryParse(_weightController.text) ?? 70.0;
    if (_weightUnit == WeightUnit.lbs) {
      return BmiCalculator.lbsToKg(val);
    }
    return val;
  }

  Future<void> _selectDateOfBirth() async {
    final initialDate = _dob ?? DateTime.now().subtract(const Duration(days: 365 * 25));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 120)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dob = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) return;

    setState(() {
      _isLoading = true;
    });

    final heightCm = _getCalculatedHeightCm();
    final weightKg = _getCalculatedWeightKg();
    final unitPref = UnitPreference(heightUnit: _heightUnit, weightUnit: _weightUnit);

    try {
      final activeProfile = ref.read(profileNotifierProvider).activeProfile;
      if (activeProfile != null) {
        await ref.read(profileNotifierProvider.notifier).updateProfileMetrics(
              profileId: activeProfile.id,
              name: _nameController.text.trim(),
              gender: _gender,
              dob: _dob,
              heightCm: heightCm,
              weightKg: weightKg,
              unitPreference: unitPref,
            );
      } else {
        await ref.read(profileNotifierProvider.notifier).createProfile(
              name: _nameController.text.trim(),
              gender: _gender,
              dob: _dob!,
              heightCm: heightCm,
              weightKg: weightKg,
              unitPreference: unitPref,
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.obese),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final heightCm = _getCalculatedHeightCm();
    final weightKg = _getCalculatedWeightKg();
    final currentBmi = BmiCalculator.calculateBmi(weightKg: weightKg, heightCm: heightCm);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Metrics Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Live BMI Calculator Preview Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'CALCULATED BMI',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentBmi > 0 ? currentBmi.toStringAsFixed(1) : '--.-',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      BmiBadge(bmi: currentBmi, isLarge: true),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Profile Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Profile Name',
                  hint: 'Self, Spouse, Child...',
                  prefixIcon: Icons.person_outline,
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 20),

                // Height Field with Unit Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Height',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    UnitToggleButton<HeightUnit>(
                      selectedValue: _heightUnit,
                      option1Value: HeightUnit.cm,
                      option1Label: 'CM',
                      option2Value: HeightUnit.ftIn,
                      option2Label: 'FT + IN',
                      onChanged: _onHeightUnitChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_heightUnit == HeightUnit.cm)
                  CustomTextField(
                    controller: _heightController,
                    label: '',
                    hint: 'Height in cm (e.g. 175)',
                    prefixIcon: Icons.height,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.validateHeightCm,
                    onChanged: (_) => setState(() {}),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _feetController,
                          label: 'Feet',
                          hint: '5',
                          prefixIcon: Icons.height,
                          keyboardType: TextInputType.number,
                          validator: Validators.validateFeet,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _inchesController,
                          label: 'Inches',
                          hint: '9',
                          keyboardType: TextInputType.number,
                          validator: Validators.validateInches,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // Weight Field with Unit Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Weight',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    UnitToggleButton<WeightUnit>(
                      selectedValue: _weightUnit,
                      option1Value: WeightUnit.kg,
                      option1Label: 'KG',
                      option2Value: WeightUnit.lbs,
                      option2Label: 'LBS',
                      onChanged: _onWeightUnitChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _weightController,
                  label: '',
                  hint: _weightUnit == WeightUnit.kg ? 'Weight in kg (e.g. 70)' : 'Weight in lbs (e.g. 154)',
                  prefixIcon: Icons.fitness_center_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) => Validators.validateWeight(val, isLbs: _weightUnit == WeightUnit.lbs),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),

                // Gender Selection (Segmented Control)
                const Text(
                  'Gender',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['Male', 'Female', 'Other'].map((g) {
                    final isSelected = _gender == g;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _gender = g;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            g,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Date of Birth Date Picker
                const Text(
                  'Date of Birth',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectDateOfBirth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: AppColors.textMuted, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _dob != null ? Validators.formatDate(_dob!) : 'Select Date of Birth',
                          style: TextStyle(
                            color: _dob != null ? AppColors.textPrimary : AppColors.textMuted,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        if (_dob != null)
                          Text(
                            '${Validators.calculateAge(_dob!)} yrs',
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save & Continue Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save & View Dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
