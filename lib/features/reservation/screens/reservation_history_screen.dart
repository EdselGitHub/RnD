import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/reservation_provider.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/stat_card.dart';
import '../../../core/constants/app_constants.dart';

class ReservationHistoryScreen extends ConsumerWidget {
  const ReservationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(reservationsStreamProvider);
    final df = DateFormat('dd MMM yyyy', 'id_ID');
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Reservasi')),
      drawer: const AppDrawer(),
      body: reservationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reservations) {
          if (reservations.isEmpty) {
            return const EmptyState(
                message: 'Belum ada riwayat reservasi',
                icon: Icons.history_rounded);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: reservations.length,
            itemBuilder: (_, i) {
              final r = reservations[i];
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
                          Text('Reservasi #${r.id.substring(0, 6)}',
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
                      const SizedBox(height: 8),
                      Text(
                        '${df.format(r.checkin)} → ${df.format(r.checkout)} (${r.nights} malam)',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
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
                                    .read(reservationNotifierProvider.notifier)
                                    .checkOut(r);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Check-out berhasil!'),
                                        backgroundColor: AppColors.success),
                                  );
                                }
                              },
                              icon: const Icon(Icons.logout, size: 16),
                              label: const Text('Check-Out'),
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
