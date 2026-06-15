import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/stat_card.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/finance_constants.dart';
import '../../../core/services/finance_export_service.dart';
import '../../../widgets/period_tab.dart';
import '../../../widgets/filter_chip_widget.dart';
import '../../../widgets/finance_summary_card.dart';
import '../../../widgets/finance_pie_chart.dart';
import '../../../widgets/finance_transaction_item.dart';

class FinanceReportScreen extends ConsumerStatefulWidget {
  const FinanceReportScreen({super.key});

  @override
  ConsumerState<FinanceReportScreen> createState() =>
      _FinanceReportScreenState();
}

class _FinanceReportScreenState extends ConsumerState<FinanceReportScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _exportAsImage() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      await FinanceExportService.exportAsImage(_repaintBoundaryKey);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal mengekspor laporan: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(financePeriodProvider);
    final category = ref.watch(financeCategoryFilterProvider);
    final selectedDate = ref.watch(financeSelectedDateProvider);
    final recordsAsync = ref.watch(financeRecordsProvider);
    final categoryAsync = ref.watch(financeByCategory);
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final df = DateFormat('dd MMM yyyy', 'id_ID');

    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: [
          _isExporting
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))),
                )
              : IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Ekspor Laporan (Gambar)',
                  onPressed: _exportAsImage,
                ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          //periode dan filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: PeriodTab(
                        label: 'Harian',
                        isSelected: period == FinancePeriod.daily,
                        onTap: () {
                          ref.read(financePeriodProvider.notifier).state =
                              FinancePeriod.daily;
                          ref.read(financeSelectedDateProvider.notifier).state =
                              DateTime.now();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PeriodTab(
                        label: 'Bulanan',
                        isSelected: period == FinancePeriod.monthly,
                        onTap: () => ref
                            .read(financePeriodProvider.notifier)
                            .state = FinancePeriod.monthly,
                      ),
                    ),
                  ],
                ),
                if (period == FinancePeriod.monthly) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                        onPressed: () {
                          final current = ref.read(financeSelectedDateProvider);
                          ref.read(financeSelectedDateProvider.notifier).state =
                              DateTime(current.year, current.month - 1, 1);
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy', 'id_ID').format(selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right,
                          color: (selectedDate.year < now.year ||
                                  (selectedDate.year == now.year &&
                                      selectedDate.month < now.month))
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                        onPressed: (selectedDate.year < now.year ||
                                (selectedDate.year == now.year &&
                                    selectedDate.month < now.month))
                            ? () {
                                ref.read(financeSelectedDateProvider.notifier).state =
                                    DateTime(selectedDate.year, selectedDate.month + 1, 1);
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChipWidget(
                        label: 'Semua',
                        isSelected: category == null,
                        color: AppColors.primary,
                        onTap: () => ref
                            .read(financeCategoryFilterProvider.notifier)
                            .state = null,
                      ),
                      ...FinanceConstants.categories.map((c) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: FilterChipWidget(
                              label: FinanceConstants.categoryLabels[c]!,
                              isSelected: category == c,
                              color: FinanceConstants.categoryColors[c]!,
                              onTap: () => ref
                                  .read(financeCategoryFilterProvider.notifier)
                                  .state = c,
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (records) {
                final grossIncome = records
                    .where((r) => r.isIncome)
                    .fold(0.0, (sum, r) => sum + r.amount);
                final totalIncome = records.fold(
                    0.0, (sum, r) => sum + (r.isIncome ? r.amount : -r.amount));

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(financeRecordsProvider);
                    ref.invalidate(financeByCategory);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    child: RepaintBoundary(
                      key: _repaintBoundaryKey,
                      child: Container(
                        color: Colors.white, //background putih untuk gambar
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //total card
                            FinanceSummaryCard(
                              category: category,
                              period: period,
                              totalIncome: totalIncome,
                              transactionCount: records.length,
                              currencyFormatter: currency,
                            ),
                            const SizedBox(height: 20),

                            //pie chart
                            categoryAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (catData) {
                                return FinancePieChart(
                                  categoryData: catData,
                                  grossIncome: grossIncome,
                                );
                              },
                            ),

                            const SizedBox(height: 16),
                            const Text('Detail Transaksi',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 8),

                            if (records.isEmpty)
                              const EmptyState(
                                  message:
                                      'Belum ada transaksi pada periode ini',
                                  icon: Icons.receipt_long_outlined)
                            else
                              ...records.map((r) => FinanceTransactionItem(
                                    record: r,
                                    currencyFormatter: currency,
                                    dateFormatter: df,
                                  )),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
