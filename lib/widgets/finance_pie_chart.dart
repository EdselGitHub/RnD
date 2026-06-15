import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/finance_constants.dart';

///widget untuk membuat pie chart pendapatan
class FinancePieChart extends StatelessWidget {
  final Map<String, double> categoryData;
  final double grossIncome;

  const FinancePieChart({
    super.key,
    required this.categoryData,
    required this.grossIncome,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribusi Pendapatan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: categoryData.entries
                            .map((e) => PieChartSectionData(
                                  value: e.value,
                                  color: FinanceConstants.categoryColors[e.key] ??
                                      AppColors.primary,
                                  title:
                                      '${grossIncome > 0 ? (e.value / grossIncome * 100).round() : 0}%',
                                  titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                  radius: 60,
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categoryData.entries
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: FinanceConstants.categoryColors[e.key],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    FinanceConstants.categoryLabels[e.key] ?? e.key,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
