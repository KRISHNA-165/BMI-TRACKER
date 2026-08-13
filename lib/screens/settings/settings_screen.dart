import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/profile_model.dart';
import '../../models/unit_preference.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/bmi_calculator.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/unit_toggle_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final UserProfile profile;

  const SettingsScreen({super.key, required this.profile});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _feetController;
  late TextEditingController _inchesController;

  late HeightUnit _heightUnit;
  late WeightUnit _weightUnit;
  late String _gender;
  late DateTime _dob;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _heightUnit = widget.profile.unitPreference.heightUnit;
    _weightUnit = widget.profile.unitPreference.weightUnit;

    final displayHeightCm = widget.profile.heightCm.toStringAsFixed(0);
    final (feet, inches) = BmiCalculator.cmToFtIn(widget.profile.heightCm);

    final displayWeight = _weightUnit == WeightUnit.kg
        ? widget.profile.weightKg.toStringAsFixed(1)
        : BmiCalculator.kgToLbs(widget.profile.weightKg).toStringAsFixed(1);

    _nameController = TextEditingController(text: widget.profile.name);
    _heightController = TextEditingController(text: displayHeightCm);
    _feetController = TextEditingController(text: feet.toString());
    _inchesController = TextEditingController(text: inches.toString());
    _weightController = TextEditingController(text: displayWeight);
    _gender = widget.profile.gender;
    _dob = widget.profile.dob;
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

  void _onHeightUnitChanged(HeightUnit newUnit) {
    if (_heightUnit == newUnit) return;

    if (newUnit == HeightUnit.ftIn) {
      final cm = double.tryParse(_heightController.text) ?? widget.profile.heightCm;
      final (ft, inch) = BmiCalculator.cmToFtIn(cm);
      _feetController.text = ft.toString();
      _inchesController.text = inch.toString();
    } else {
      final ft = int.tryParse(_feetController.text) ?? 5;
      final inch = int.tryParse(_inchesController.text) ?? 7;
      final cm = BmiCalculator.ftInToCm(ft, inch);
      _heightController.text = cm.toStringAsFixed(0);
    }

    setState(() {
      _heightUnit = newUnit;
    });
  }

  void _onWeightUnitChanged(WeightUnit newUnit) {
    if (_weightUnit == newUnit) return;

    final currentWeight = double.tryParse(_weightController.text) ?? widget.profile.weightKg;
    if (newUnit == WeightUnit.lbs) {
      final lbs = BmiCalculator.kgToLbs(currentWeight);
      _weightController.text = lbs.toStringAsFixed(1);
    } else {
      final kg = BmiCalculator.lbsToKg(currentWeight);
      _weightController.text = kg.toStringAsFixed(1);
    }

    setState(() {
      _weightUnit = newUnit;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    double heightCm;
    if (_heightUnit == HeightUnit.cm) {
      heightCm = double.tryParse(_heightController.text) ?? widget.profile.heightCm;
    } else {
      final ft = int.tryParse(_feetController.text) ?? 5;
      final inch = int.tryParse(_inchesController.text) ?? 7;
      heightCm = BmiCalculator.ftInToCm(ft, inch);
    }

    final rawWeight = double.tryParse(_weightController.text) ?? widget.profile.weightKg;
    final weightKg = _weightUnit == WeightUnit.kg ? rawWeight : BmiCalculator.lbsToKg(rawWeight);

    try {
      await ref.read(profileNotifierProvider.notifier).updateProfileMetrics(
            profileId: widget.profile.id,
            name: _nameController.text.trim(),
            gender: _gender,
            dob: _dob,
            heightCm: heightCm,
            weightKg: weightKg,
            unitPreference: UnitPreference(heightUnit: _heightUnit, weightUnit: _weightUnit),
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings updated! Weight logged in history.'),
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
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
                // Profile Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Profile Name',
                  prefixIcon: Icons.person_outline,
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 20),

                // Height Field & Unit Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Height', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
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
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // Weight Field & Unit Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Weight', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
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
                  hint: 'Weight',
                  prefixIcon: Icons.fitness_center_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) => Validators.validateWeight(val, isLbs: _weightUnit == WeightUnit.lbs),
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveSettings,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes & Update Weight'),
                ),
                const SizedBox(height: 24),

                // Sign Out Option
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  },
                  icon: const Icon(Icons.logout, color: AppColors.obese, size: 20),
                  label: const Text('Sign Out', style: TextStyle(color: AppColors.obese)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.obese),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
