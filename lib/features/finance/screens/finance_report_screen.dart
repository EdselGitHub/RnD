import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/stat_card.dart';
import '../../../core/constants/app_constants.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FinanceReportScreen extends ConsumerStatefulWidget {
  const FinanceReportScreen({super.key});

  @override
  ConsumerState<FinanceReportScreen> createState() => _FinanceReportScreenState();
}

class _FinanceReportScreenState extends ConsumerState<FinanceReportScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _exportAsImage() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Tidak dapat merender laporan.');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Buat PDF
      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(pdfImage),
            );
          },
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/laporan_keuangan_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: 'Laporan Keuangan RnD Dewi Sri Bali');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor laporan: $e'), backgroundColor: AppColors.error),
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
    final recordsAsync = ref.watch(financeRecordsProvider);
    final categoryAsync = ref.watch(financeByCategory);
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final df = DateFormat('dd MMM yyyy', 'id_ID');

    const categories = ['penjualan kamar', 'motor', 'laundry', 'minuman', 'pengeluaran'];
    const categoryColors = {
      'penjualan kamar': AppColors.cardRoom,
      'motor': AppColors.cardMotor,
      'laundry': AppColors.cardLaundry,
      'minuman': AppColors.cardDrink,
      'pengeluaran': AppColors.error,
    };
    const categoryLabels = {
      'penjualan kamar': 'Kamar',
      'motor': 'Motor',
      'laundry': 'Laundry',
      'minuman': 'Minuman',
      'pengeluaran': 'Pengeluaran',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: [
          _isExporting
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
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
          // Period & Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PeriodTab(
                        label: 'Harian',
                        isSelected: period == FinancePeriod.daily,
                        onTap: () => ref
                            .read(financePeriodProvider.notifier)
                            .state = FinancePeriod.daily,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PeriodTab(
                        label: 'Bulanan',
                        isSelected: period == FinancePeriod.monthly,
                        onTap: () => ref
                            .read(financePeriodProvider.notifier)
                            .state = FinancePeriod.monthly,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Semua',
                        isSelected: category == null,
                        color: AppColors.primary,
                        onTap: () => ref
                            .read(financeCategoryFilterProvider.notifier)
                            .state = null,
                      ),
                      ...categories.map((c) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _FilterChip(
                          label: categoryLabels[c]!,
                          isSelected: category == c,
                          color: categoryColors[c]!,
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
                final totalIncome = records
                    .fold(0.0, (sum, r) => sum + (r.isIncome ? r.amount : -r.amount));

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
                        color: Colors.white, // ensure background is white for the image
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Total Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppDimensions.paddingM),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: category == 'pengeluaran'
                                      ? [AppColors.error, const Color(0xFFD32F2F)]
                                      : [AppColors.cardFinance, const Color(0xFF388E3C)],
                                ),
                                borderRadius:
                                    BorderRadius.circular(AppDimensions.radiusL),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    period == FinancePeriod.daily
                                        ? (category == 'pengeluaran' ? 'Total Pengeluaran Hari Ini' : 'Total Pendapatan Hari Ini')
                                        : (category == 'pengeluaran' ? 'Total Pengeluaran Bulan Ini' : 'Total Pendapatan Bulan Ini'),
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(currency.format(category == 'pengeluaran' ? totalIncome.abs() : totalIncome),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold)),
                                  Text('${records.length} transaksi',
                                      style: const TextStyle(
                                          color: Colors.white60, fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Pie Chart
                            categoryAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (catData) {
                                if (catData.isEmpty) return const SizedBox.shrink();
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Distribusi Pendapatan',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15)),
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
                                                    sections: catData.entries
                                                        .map((e) => PieChartSectionData(
                                                              value: e.value,
                                                              color: categoryColors[e.key] ??
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
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: catData.entries
                                                    .map((e) => Padding(
                                                          padding:
                                                              const EdgeInsets.only(bottom: 8),
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                width: 12,
                                                                height: 12,
                                                                decoration: BoxDecoration(
                                                                  color: categoryColors[e.key],
                                                                  shape: BoxShape.circle,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 6),
                                                              Text(
                                                                categoryLabels[e.key] ?? e.key,
                                                                style:
                                                                    const TextStyle(fontSize: 12),
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
                              },
                            ),

                            const SizedBox(height: 16),
                            const Text('Detail Transaksi',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 8),

                            if (records.isEmpty)
                              const EmptyState(
                                  message: 'Belum ada transaksi pada periode ini',
                                  icon: Icons.receipt_long_outlined)
                            else
                              ...records.map((r) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(
                                          color: (!r.isIncome 
                                              ? AppColors.error 
                                              : (categoryColors[r.category] ?? AppColors.primary))
                                              .withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          !r.isIncome ? Icons.money_off_rounded : _categoryIcon(r.category),
                                          color: !r.isIncome 
                                              ? AppColors.error 
                                              : (categoryColors[r.category] ?? AppColors.primary),
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(r.description,
                                          style: const TextStyle(fontSize: 13)),
                                      subtitle: Text(df.format(r.date),
                                          style: const TextStyle(fontSize: 11)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            currency.format(r.amount),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: r.isIncome
                                                  ? AppColors.success
                                                  : AppColors.error,
                                            ),
                                          ),
                                          if (r.kartuIdentitas != null && r.kartuIdentitas!.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.badge_outlined, size: 20, color: AppColors.primary),
                                              tooltip: 'Lihat Kartu Identitas',
                                              onPressed: () async {
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (_) => const Center(child: CircularProgressIndicator()),
                                                );
                                                try {
                                                  // get download url since admin has read access
                                                  final url = await FirebaseStorage.instance
                                                      .ref(r.kartuIdentitas)
                                                      .getDownloadURL();
                                                  if (!context.mounted) return;
                                                  Navigator.pop(context); // close loading
                                                  showDialog(
                                                    context: context,
                                                    builder: (_) => AlertDialog(
                                                      title: const Text('Kartu Identitas'),
                                                      content: Image.network(url),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context),
                                                          child: const Text('Tutup'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                } catch (e) {
                                                  if (!context.mounted) return;
                                                  Navigator.pop(context); // close loading
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Gagal memuat KTP: $e')),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
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

  IconData _categoryIcon(String category) {
    if (category == 'pengeluaran') return Icons.money_off_rounded;
    switch (category) {
      case 'penjualan kamar':
        return Icons.hotel_rounded;
      case 'motor':
        return Icons.two_wheeler_rounded;
      case 'laundry':
        return Icons.local_laundry_service_rounded;
      case 'minuman':
        return Icons.local_drink_rounded;
      default:
        return Icons.payments_rounded;
    }
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodTab(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.isSelected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
