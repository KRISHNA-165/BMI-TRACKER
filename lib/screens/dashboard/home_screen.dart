import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/unit_preference.dart';
import '../../providers/profile_provider.dart';
import '../../providers/weight_history_provider.dart';
import '../../utils/app_config.dart';
import '../../utils/bmi_calculator.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/bmi_badge.dart';
import '../../widgets/demo_mode_banner.dart';
import '../../widgets/profile_switcher.dart';
import '../../widgets/weight_chart.dart';
import '../profile/add_profile_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showQuickLogWeightModal(BuildContext context, WidgetRef ref) {
    final profileState = ref.read(profileNotifierProvider);
    final activeProfile = profileState.activeProfile;
    if (activeProfile == null) return;

    final isLbs = activeProfile.unitPreference.weightUnit == WeightUnit.lbs;
    final currentWeightDisp = isLbs
        ? BmiCalculator.kgToLbs(activeProfile.weightKg).toStringAsFixed(1)
        : activeProfile.weightKg.toStringAsFixed(1);

    final controller = TextEditingController(text: currentWeightDisp);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Log Weight for ${activeProfile.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                decoration: InputDecoration(
                  labelText: isLbs ? 'Weight (lbs)' : 'Weight (kg)',
                  prefixIcon: const Icon(Icons.fitness_center, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final inputVal = double.tryParse(controller.text);
                  if (inputVal == null || inputVal <= 0) return;

                  final weightKg = isLbs ? BmiCalculator.lbsToKg(inputVal) : inputVal;

                  try {
                    await ref.read(profileNotifierProvider.notifier).updateProfileMetrics(
                          profileId: activeProfile.id,
                          weightKg: weightKg,
                        );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Weight logged and BMI recalculated!'),
                          backgroundColor: AppColors.normalWeight,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save to Firestore: ${e.toString()}'),
                          backgroundColor: AppColors.overweight,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Save & Update History'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileNotifierProvider);
    final weightHistoryState = ref.watch(weightHistoryProvider);

    final isDemoMode = AppConfig.isDemoMode;

    if (profileState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final activeProfile = profileState.activeProfile;
    if (activeProfile == null) {
      return const Scaffold(
        body: Center(child: Text('No active profile found.')),
      );
    }

    final isLbs = activeProfile.unitPreference.weightUnit == WeightUnit.lbs;
    final isFtIn = activeProfile.unitPreference.heightUnit == HeightUnit.ftIn;

    final displayWeight = isLbs
        ? '${BmiCalculator.kgToLbs(activeProfile.weightKg).toStringAsFixed(1)} lbs'
        : '${activeProfile.weightKg.toStringAsFixed(1)} kg';

    final displayHeight = isFtIn
        ? (() {
            final (ft, inch) = BmiCalculator.cmToFtIn(activeProfile.heightCm);
            return "$ft' $inch\"";
          })()
        : '${activeProfile.heightCm.round()} cm';

    final ageYears = Validators.calculateAge(activeProfile.dob);
    final categoryDetails = BmiCalculator.getCategoryDetails(activeProfile.currentBmi);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (isDemoMode) const DemoModeBanner(),

            // Top Header: Profile Switcher & Settings Icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ProfileSwitcher(
                    profiles: profileState.profiles,
                    activeProfile: activeProfile,
                    onProfileSelected: (profile) {
                      ref.read(profileNotifierProvider.notifier).setActiveProfile(profile);
                    },
                    onAddProfile: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddProfileScreen()),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 26),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(profile: activeProfile),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Hero BMI Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.cardGradient,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: categoryDetails.color.withAlpha(25),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'CURRENT BMI',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              BmiBadge(bmi: activeProfile.currentBmi),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            activeProfile.currentBmi.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            categoryDetails.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Metrics Summary Grid
                    Row(
                      children: [
                        _buildMetricTile(
                          icon: Icons.fitness_center,
                          label: 'Weight',
                          value: displayWeight,
                          accentColor: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        _buildMetricTile(
                          icon: Icons.height,
                          label: 'Height',
                          value: displayHeight,
                          accentColor: AppColors.secondary,
                        ),
                        const SizedBox(width: 12),
                        _buildMetricTile(
                          icon: Icons.cake_outlined,
                          label: 'Age',
                          value: '$ageYears yrs',
                          accentColor: AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Weight History Header & Quick Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Weight History (7 Days)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showQuickLogWeightModal(context, ref),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Log Weight'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryLight,
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Weight Line Chart Widget
                    WeightChart(
                      entries: weightHistoryState.last7DaysEntries,
                      weightUnit: activeProfile.unitPreference.weightUnit,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: accentColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
