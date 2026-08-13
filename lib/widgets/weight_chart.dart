import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/unit_preference.dart';
import '../models/weight_entry_model.dart';
import '../utils/bmi_calculator.dart';
import '../utils/constants.dart';

class WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  final WeightUnit weightUnit;

  const WeightChart({
    super.key,
    required this.entries,
    this.weightUnit = WeightUnit.kg,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return Container(
        height: 200,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 44,
              color: AppColors.textMuted.withAlpha(150),
            ),
            const SizedBox(height: 12),
            const Text(
              'Log your weight a few times to see your trend',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Sort entries chronologically
    final sortedEntries = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

    // Convert weights if user unit preference is lbs
    final isLbs = weightUnit == WeightUnit.lbs;
    final spots = <FlSpot>[];

    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < sortedEntries.length; i++) {
      final w = isLbs
          ? BmiCalculator.kgToLbs(sortedEntries[i].weightKg)
          : sortedEntries[i].weightKg;
      final val = double.parse(w.toStringAsFixed(1));
      spots.add(FlSpot(i.toDouble(), val));

      if (val < minY) minY = val;
      if (val > maxY) maxY = val;
    }

    // Add padding to Y range so chart lines don't hit extreme top/bottom
    final yRange = maxY - minY;
    final yPadding = yRange == 0 ? 5.0 : (yRange * 0.2);
    final chartMinY = (minY - yPadding).clamp(0.0, double.infinity);
    final chartMaxY = maxY + yPadding;

    return Container(
      height: 240,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.border.withAlpha(80),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedEntries.length) {
                    final date = sortedEntries[index].loggedAt;
                    // Format Day name (e.g. Mon, Tue) or date
                    final label = DateFormat('E').format(date);
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final dateStr = index < sortedEntries.length
                      ? DateFormat('dd MMM').format(sortedEntries[index].loggedAt)
                      : '';
                  final unitStr = isLbs ? 'lbs' : 'kg';
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)} $unitStr\n$dateStr',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.primary,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: AppColors.secondary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withAlpha(90),
                    AppColors.primary.withAlpha(0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
