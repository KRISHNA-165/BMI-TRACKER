import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/unit_preference.dart';
import '../../providers/profile_provider.dart';
import '../../utils/bmi_calculator.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/unit_toggle_button.dart';

class AddProfileScreen extends ConsumerStatefulWidget {
  const AddProfileScreen({super.key});

  @override
  ConsumerState<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends ConsumerState<AddProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _weightController = TextEditingController(text: '65');
  final _heightController = TextEditingController(text: '165');
  final _feetController = TextEditingController(text: '5');
  final _inchesController = TextEditingController(text: '5');

  HeightUnit _heightUnit = HeightUnit.cm;
  WeightUnit _weightUnit = WeightUnit.kg;
  String _gender = 'Female';
  DateTime? _dob = DateTime.now().subtract(const Duration(days: 365 * 20));

  bool _isLoading = false;

  /// Switch height unit with lossless internal conversion
  void _onHeightUnitChanged(HeightUnit newUnit) {
    if (_heightUnit == newUnit) return;

    if (newUnit == HeightUnit.ftIn) {
      // CM → FT+IN
      final cm = double.tryParse(_heightController.text) ?? 165.0;
      final (ft, inch) = BmiCalculator.cmToFtIn(cm);
      _feetController.text = ft.toString();
      _inchesController.text = inch.toString();
    } else {
      // FT+IN → CM
      final ft = int.tryParse(_feetController.text) ?? 5;
      final inch = int.tryParse(_inchesController.text) ?? 5;
      final cm = BmiCalculator.ftInToCm(ft, inch);
      _heightController.text = cm.toStringAsFixed(0);
    }

    setState(() => _heightUnit = newUnit);
  }

  /// Switch weight unit with lossless internal conversion
  void _onWeightUnitChanged(WeightUnit newUnit) {
    if (_weightUnit == newUnit) return;

    final current = double.tryParse(_weightController.text) ?? 65.0;
    if (newUnit == WeightUnit.lbs) {
      _weightController.text = BmiCalculator.kgToLbs(current).toStringAsFixed(1);
    } else {
      _weightController.text = BmiCalculator.lbsToKg(current).toStringAsFixed(1);
    }

    setState(() => _weightUnit = newUnit);
  }

  /// Canonical height in CM regardless of displayed unit
  double get _heightCm {
    if (_heightUnit == HeightUnit.cm) {
      return double.tryParse(_heightController.text) ?? 165.0;
    } else {
      final ft = int.tryParse(_feetController.text) ?? 5;
      final inch = int.tryParse(_inchesController.text) ?? 5;
      return BmiCalculator.ftInToCm(ft, inch);
    }
  }

  /// Canonical weight in KG regardless of displayed unit
  double get _weightKg {
    final val = double.tryParse(_weightController.text) ?? 65.0;
    return _weightUnit == WeightUnit.kg ? val : BmiCalculator.lbsToKg(val);
  }

  Future<void> _selectDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
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
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date of birth.'),
          backgroundColor: AppColors.obese,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(profileNotifierProvider.notifier).createProfile(
            name: _nameController.text.trim(),
            gender: _gender,
            dob: _dob!,
            heightCm: _heightCm,
            weightKg: _weightKg,
            unitPreference: UnitPreference(heightUnit: _heightUnit, weightUnit: _weightUnit),
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile "${_nameController.text.trim()}" created!'),
            backgroundColor: AppColors.normalWeight,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.obese),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Profile'),
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
                const Text(
                  'Add a Family Member Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Track independent body metrics and BMI history under one account.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Profile Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Profile Name',
                  hint: 'Spouse, Child, Father...',
                  prefixIcon: Icons.person_outline,
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 20),

                // Height with Ft+In support
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Height',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14,fontWeight: FontWeight.w500)),
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
                    hint: 'Height in cm (e.g. 165)',
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

                // Weight with KG/LBS toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Weight',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
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
                  hint: _weightUnit == WeightUnit.kg ? 'Weight in kg (e.g. 65)' : 'Weight in lbs (e.g. 143)',
                  prefixIcon: Icons.fitness_center_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) => Validators.validateWeight(val, isLbs: _weightUnit == WeightUnit.lbs),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),

                // Gender
                const Text('Gender',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: ['Male', 'Female', 'Other'].map((g) {
                    final isSelected = _gender == g;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _gender = g),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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

                // Date of Birth
                const Text('Date of Birth',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectDob,
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

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
