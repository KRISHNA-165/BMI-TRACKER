import 'package:flutter/material.dart';
import '../utils/constants.dart';

class UnitToggleButton<T> extends StatelessWidget {
  final T selectedValue;
  final T option1Value;
  final String option1Label;
  final T option2Value;
  final String option2Label;
  final ValueChanged<T> onChanged;

  const UnitToggleButton({
    super.key,
    required this.selectedValue,
    required this.option1Value,
    required this.option1Label,
    required this.option2Value,
    required this.option2Label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isOption1Selected = selectedValue == option1Value;

    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            context,
            label: option1Label,
            isSelected: isOption1Selected,
            onTap: () => onChanged(option1Value),
          ),
          _buildButton(
            context,
            label: option2Label,
            isSelected: !isOption1Selected,
            onTap: () => onChanged(option2Value),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
