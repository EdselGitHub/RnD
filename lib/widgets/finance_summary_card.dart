import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../features/finance/providers/finance_provider.dart';

class FinanceSummaryCard extends StatelessWidget {
  final String? category;
  final FinancePeriod period;
  final double totalIncome;
  final int transactionCount;
  final NumberFormat currencyFormatter;

  const FinanceSummaryCard({
    super.key,
    required this.category,
    required this.period,
    required this.totalIncome,
    required this.transactionCount,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: category == 'pengeluaran'
              ? [AppColors.error, const Color(0xFFD32F2F)]
              : [AppColors.cardFinance, const Color(0xFF388E3C)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            period == FinancePeriod.daily
                ? (category == 'pengeluaran'
                    ? 'Total Pengeluaran Hari Ini'
                    : 'Total Pendapatan Hari Ini')
                : (category == 'pengeluaran'
                    ? 'Total Pengeluaran Bulan Ini'
                    : 'Total Pendapatan Bulan Ini'),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormatter.format(
                category == 'pengeluaran' ? totalIncome.abs() : totalIncome),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$transactionCount transaksi',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
