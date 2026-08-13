import 'package:flutter/material.dart';
import '../utils/bmi_calculator.dart';

class BmiBadge extends StatelessWidget {
  final double bmi;
  final bool isLarge;

  const BmiBadge({
    super.key,
    required this.bmi,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final details = BmiCalculator.getCategoryDetails(bmi);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 16 : 12,
        vertical: isLarge ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: details.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: details.color.withAlpha(120), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isLarge ? 10 : 8,
            height: isLarge ? 10 : 8,
            decoration: BoxDecoration(
              color: details.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            details.label,
            style: TextStyle(
              color: details.color,
              fontSize: isLarge ? 14 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
