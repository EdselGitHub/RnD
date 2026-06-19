import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/motor_provider.dart';
import '../../../core/models/motorcycle_model.dart';
import '../../../core/models/motor_rental_model.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/stat_card.dart';
import '../../../core/constants/app_constants.dart';

class MotorcycleListScreen extends ConsumerWidget {
  const MotorcycleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motorcyclesAsync = ref.watch(motorcyclesStreamProvider);
    final rentalsAsync = ref.watch(motorRentalsStreamProvider);
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Penyewaan Motor'),
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

              List<MotorRentalModel> motorRentals = [];
              if (!isAvailable && rentalsAsync is AsyncData) {
                final now = DateTime.now();
                motorRentals = rentalsAsync.value!.where((res) => 
                  res.motorId == m.id && 
                  res.status == 'aktif' &&
                  now.compareTo(res.tanggalSelesai) < 0
                ).toList();
                motorRentals.sort((a, b) => a.tanggal.compareTo(b.tanggal));
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? AppColors.available.withOpacity(0.12)
                                  : AppColors.occupied.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                            ),
                            child: Icon(Icons.two_wheeler_rounded,
                                color: isAvailable
                                    ? AppColors.available
                                    : AppColors.occupied),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.nama,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('${currency.format(m.harga)}/hari',
                                    style: const TextStyle(fontSize: 12)),
                                ...motorRentals.map((res) => Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Disewa: ${DateFormat('dd MMM').format(res.tanggal)} - ${DateFormat('dd MMM yyyy').format(res.tanggalSelesai)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              StatusBadge(
                                label: isAvailable
                                    ? AppStrings.motorAvailable
                                    : AppStrings.motorRented,
                                color: isAvailable
                                    ? AppColors.available
                                    : AppColors.occupied,
                              ),
                              if (isAvailable) ...[
                                const SizedBox(height: 6),
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
                              if (!isAvailable) ...[
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Opsi Motor Disewa'),
                                        content: SizedBox(
                                          width: double.maxFinite,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Pilih tanggal sewa yang ingin diselesaikan:'),
                                              const SizedBox(height: 12),
                                              ...motorRentals.map((res) {
                                                final dateStr = '${DateFormat('dd MMM yyyy').format(res.tanggal)} - ${DateFormat('dd MMM yyyy').format(res.tanggalSelesai)}';
                                                return Card(
                                                  elevation: 0,
                                                  color: Colors.grey.shade100,
                                                  margin: const EdgeInsets.only(bottom: 8),
                                                  child: ListTile(
                                                    title: Text(dateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                                    trailing: ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: AppColors.error,
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                                        minimumSize: const Size(60, 30),
                                                      ),
                                                      onPressed: () async {
                                                        await ref.read(motorNotifierProvider.notifier).returnMotor(res);
                                                        if (ctx.mounted) {
                                                          Navigator.pop(ctx);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Sewa motor pada tanggal $dateStr berhasil diselesaikan!'),
                                                              backgroundColor: AppColors.success,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      child: const Text('Selesai', style: TextStyle(color: Colors.white, fontSize: 12)),
                                                    ),
                                                  ),
                                                );
                                              }),
                                              if (motorRentals.isEmpty)
                                                ListTile(
                                                  title: const Text('Tidak ada sewa aktif.'),
                                                  trailing: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                                    onPressed: () async {
                                                      await ref.read(motorNotifierProvider.notifier).setMotorTersedia(m.id);
                                                      if (ctx.mounted) {
                                                        Navigator.pop(ctx);
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(
                                                            content: Text('Motor berhasil diubah ke tersedia!'),
                                                            backgroundColor: AppColors.success,
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: const Text('Tersediakan Paksa', style: TextStyle(color: Colors.white, fontSize: 12)),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Batal'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              context.push('/motor-rentals/add',
                                                  extra: {'motorcycleId': m.id, 'plateNumber': m.nama});
                                            },
                                            child: const Text('Tambah Sewa Baru'),
                                          ),
                                        ],
                                      ),
                                    );
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
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
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
                    ],
                  ),
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
                  status: AppStrings.motorAvailable,
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
