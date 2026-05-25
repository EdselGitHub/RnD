import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/dashboard_provider.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/stat_card.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final userAsync = ref.watch(currentUserModelProvider);
    final isKaryawan = userAsync.value?.role == 'karyawan';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dashboardStatsProvider),
          ),
        ],
      ),
      drawer: const AppDrawer(),


      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     final stopwatch = Stopwatch()..start();
      //     try {
      //       await FirebaseFirestore.instance.collection('performance_test').get();
            
      //       stopwatch.stop();
      //       final msg = '✅ Waktu Fetch: ${stopwatch.elapsedMilliseconds} ms';
      //       debugPrint(msg);
            
      //       if (context.mounted) {
      //         ScaffoldMessenger.of(context).showSnackBar(
      //           SnackBar(
      //             content: Text(msg),
      //             backgroundColor: Colors.green,
      //           ),
      //         );
      //       }
      //     } catch (e) {
      //       final msg = '❌ Error saat fetch: $e';
      //       debugPrint(msg);
            
      //       if (context.mounted) {
      //         ScaffoldMessenger.of(context).showSnackBar(
      //           SnackBar(
      //             content: Text(msg),
      //             backgroundColor: AppColors.error,
      //           ),
      //         );
      //       }
      //     }
      //   },
      //   backgroundColor: AppColors.primary,
      //   tooltip: 'Test Firebase Get Performance',
      //   child: const Icon(Icons.speed, color: Colors.white),
      // ),


      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardStatsProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Selamat Datang! 👋',
                                style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 4),
                            const Text('RnD Dewi Sri Bali',
                                style: TextStyle(color: Colors.white,
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.hotel_rounded, color: Colors.white38, size: 52),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Ringkasan Hari Ini',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                  children: [
                    StatCard(
                      title: 'Kamar Terisi',
                      value: '${stats.occupiedRooms}/${stats.totalRooms}',
                      icon: Icons.hotel_rounded,
                      color: AppColors.cardRoom,
                      subtitle: 'dari total kamar',
                      onTap: () => context.go('/rooms'),
                    ),
                    StatCard(
                      title: 'Motor Disewa',
                      value: '${stats.rentedMotors}/${stats.totalMotors}',
                      icon: Icons.two_wheeler_rounded,
                      color: AppColors.cardMotor,
                      subtitle: 'unit aktif',
                      onTap: () => context.go('/motorcycles'),
                    ),
                    if (!isKaryawan)
                      StatCard(
                        title: 'Pendapatan Hari Ini',
                        value: currency.format(stats.todayIncome),
                        icon: Icons.payments_rounded,
                        color: AppColors.cardFinance,
                        subtitle: 'total pemasukan',
                        onTap: () => context.go('/finance'),
                      ),
                    StatCard(
                      title: 'Stok Rendah',
                      value: '${stats.lowStockDrinks.length}',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      subtitle: 'jenis minuman',
                      onTap: () => context.go('/drinks'),
                    ),
                  ],
                ),

                // Low stock warning
                if (stats.lowStockDrinks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                            SizedBox(width: 8),
                            Text('Stok Minuman Rendah',
                                style: TextStyle(fontWeight: FontWeight.bold,
                                    color: AppColors.warning)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...stats.lowStockDrinks.map((name) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 6, color: AppColors.warning),
                              const SizedBox(width: 8),
                              Text(name, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                const Text('Menu Cepat',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _QuickMenuGrid(isKaryawan: isKaryawan),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickMenuGrid extends ConsumerWidget {
  final bool isKaryawan;
  const _QuickMenuGrid({this.isKaryawan = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      ('Laundry', Icons.local_laundry_service_rounded, AppColors.cardLaundry, () => context.go('/laundry')),
      ('Room Service', Icons.cleaning_services_rounded, AppColors.secondary, () => context.go('/room-service')),
      ('Jual Minuman', Icons.local_drink_rounded, AppColors.cardDrink, () => context.go('/drinks')),
      if (!isKaryawan)
        ('Laporan', Icons.bar_chart_rounded, AppColors.primary, () => context.go('/finance')),
      ('Pengeluaran', Icons.money_off_rounded, AppColors.error, () => AppDrawer.showExpenseDialog(context)),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map((item) {
        return InkWell(
          onTap: item.$4,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: item.$3.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Icon(item.$2, color: item.$3, size: 26),
              ),
              const SizedBox(height: 6),
              Text(item.$1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
