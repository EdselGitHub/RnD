import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/motor_provider.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/stat_card.dart';
import '../../../core/constants/app_constants.dart';

class RentalHistoryScreen extends ConsumerWidget {
  const RentalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rentalsAsync = ref.watch(motorRentalsStreamProvider);
    final df = DateFormat('dd MMM yyyy', 'id_ID');
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Penyewaan Motor')),
      drawer: const AppDrawer(),
      body: rentalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rentals) {
          if (rentals.isEmpty) {
            return const EmptyState(
                message: 'Belum ada riwayat penyewaan',
                icon: Icons.history_rounded);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: rentals.length,
            itemBuilder: (_, i) {
              final r = rentals[i];
              final isActive = r.status == 'aktif';
              final isCancelled = r.status == 'dibatalkan';
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Sewa #${r.id.substring(0, 6)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          StatusBadge(
                            label: isActive
                                ? 'Aktif'
                                : isCancelled
                                    ? 'Dibatalkan'
                                    : 'Selesai',
                            color: isActive
                                ? AppColors.warning
                                : isCancelled
                                    ? AppColors.error
                                    : AppColors.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Tanggal: ${df.format(r.tanggal)}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      Text('Harga/hari: ${currency.format(r.hargaPerhari)}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(currency.format(r.total),
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const Spacer(),
                          if (isActive)
                            TextButton.icon(
                              onPressed: () async {
                                await ref
                                    .read(motorNotifierProvider.notifier)
                                    .returnMotor(r);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Motor berhasil dikembalikan!'),
                                        backgroundColor: AppColors.success),
                                  );
                                }
                              },
                              icon: const Icon(Icons.assignment_return, size: 16),
                              label: const Text('Kembalikan'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
