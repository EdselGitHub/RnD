import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/motor_provider.dart';
import '../../../core/models/motorcycle_model.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/stat_card.dart';
import '../../../core/constants/app_constants.dart';

class MotorcycleListScreen extends ConsumerWidget {
  const MotorcycleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motorcyclesAsync = ref.watch(motorcyclesStreamProvider);
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Penyewaan Motor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/motor-rentals/history'),
            tooltip: 'Riwayat',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: motorcyclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (motorcycles) {
          if (motorcycles.isEmpty) {
            return const EmptyState(
                message: 'Belum ada data motor',
                icon: Icons.two_wheeler_outlined);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: motorcycles.length,
            itemBuilder: (_, i) {
              final m = motorcycles[i];
              final isAvailable = m.isAvailable;
              final isMaintenance = m.status == 'maintenance';
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(AppDimensions.paddingM),
                      leading: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? AppColors.available.withOpacity(0.12)
                              : isMaintenance
                                  ? AppColors.warning.withOpacity(0.12)
                                  : AppColors.occupied.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        ),
                        child: Icon(Icons.two_wheeler_rounded,
                            color: isAvailable
                                ? AppColors.available
                                : isMaintenance
                                    ? AppColors.warning
                                    : AppColors.occupied),
                      ),
                      title: Text(m.nama,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${currency.format(m.harga)}/hari',
                          style: const TextStyle(fontSize: 12)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StatusBadge(
                            label: isAvailable
                                ? AppStrings.motorAvailable
                                : isMaintenance
                                    ? 'Maintenance'
                                    : AppStrings.motorRented,
                            color: isAvailable
                                ? AppColors.available
                                : isMaintenance
                                    ? AppColors.warning
                                    : AppColors.occupied,
                          ),
                          if (isAvailable) ...[
                            const SizedBox(height: 7),
                            GestureDetector(
                              onTap: () => context.push('/motor-rentals/add',
                                  extra: {'motorcycleId': m.id, 'plateNumber': m.nama}),
                              child: const Text('Sewa',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                          if (m.status == 'disewa') ...[
                            const SizedBox(height: 7),
                            GestureDetector(
                              onTap: () async {
                                await ref
                                    .read(motorNotifierProvider.notifier)
                                    .setMotorTersedia(m.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Motor berhasil diubah ke tersedia!'),
                                        backgroundColor: AppColors.success),
                                  );
                                }
                              },
                              child: const Text('Tersediakan',
                                  style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => _showDeleteMotorDialog(context, ref, m),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.delete_outlined, size: 16, color: AppColors.error),
                                  SizedBox(width: 6),
                                  Text('Hapus',
                                      style: TextStyle(
                                          color: AppColors.error,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMotorDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMotorDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Motor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Motor')),
              const SizedBox(height: 8),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga/hari')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                final motor = MotorcycleModel(
                  id: '',
                  nama: nameCtrl.text.trim(),
                  harga: double.tryParse(priceCtrl.text) ?? 0,
                  status: 'tersedia',
                );
                await ref.read(motorNotifierProvider.notifier).addMotorcycle(motor);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteMotorDialog(BuildContext context, WidgetRef ref, MotorcycleModel m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Motor'),
        content: Text('Yakin ingin menghapus motor "${m.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref
                  .read(motorNotifierProvider.notifier)
                  .deleteMotor(m.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Motor "${m.nama}" berhasil dihapus'),
                      backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
