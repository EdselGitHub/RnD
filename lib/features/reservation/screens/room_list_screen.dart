import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/reservation_provider.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/reservation_model.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/stat_card.dart';
import '../../../core/constants/app_constants.dart';

class RoomListScreen extends ConsumerWidget {
  const RoomListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsStreamProvider);
    final reservationsAsync = ref.watch(reservationsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kamar')),
      drawer: const AppDrawer(),
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rooms) {
          if (rooms.isEmpty) {
            return const EmptyState(
                message: 'Belum ada data kamar',
                icon: Icons.hotel_outlined);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: rooms.length,
            itemBuilder: (_, i) {
              final room = rooms[i];
              final isAvailable = room.isAvailable;
              final isMaintenance = room.status == 'maintenance';
              final currency = NumberFormat.currency(
                  locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
              
              List<ReservationModel> roomReservations = [];
              if (!isAvailable && !isMaintenance && reservationsAsync is AsyncData) {
                final now = DateTime.now();
                roomReservations = reservationsAsync.value!.where((res) => 
                  res.roomId == room.id && 
                  res.status == 'aktif' &&
                  now.compareTo(res.checkout) < 0
                ).toList();
                roomReservations.sort((a, b) => a.checkin.compareTo(b.checkin));
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? AppColors.available.withOpacity(0.12)
                                  : isMaintenance
                                      ? AppColors.warning.withOpacity(0.12)
                                      : AppColors.occupied.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                            ),
                            child: Icon(Icons.hotel_rounded,
                                color: isAvailable
                                    ? AppColors.available
                                    : isMaintenance
                                        ? AppColors.warning
                                        : AppColors.occupied),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(room.nama,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('${currency.format(room.harga)}/malam',
                                    style: const TextStyle(fontSize: 12)),
                                ...roomReservations.map((res) => Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Terisi: ${DateFormat('dd MMM').format(res.checkin)} - ${DateFormat('dd MMM yyyy').format(res.checkout)}',
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
                                    ? AppStrings.roomAvailable
                                    : isMaintenance
                                        ? 'Maintenance'
                                        : AppStrings.roomOccupied,
                                color: isAvailable
                                    ? AppColors.available
                                    : isMaintenance
                                        ? AppColors.warning
                                        : AppColors.occupied,
                              ),
                              if (isAvailable) ...[
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => context.push('/reservations/add',
                                      extra: {'roomId': room.id, 'roomNumber': room.nama}),
                                  child: const Text('Reservasi',
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                              if (!isAvailable && !isMaintenance) ...[
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Opsi Kamar Terisi'),
                                        content: SizedBox(
                                          width: double.maxFinite,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Pilih tanggal terisi yang ingin dihapus (Checkout):'),
                                              const SizedBox(height: 12),
                                              ...roomReservations.map((res) {
                                                final dateStr = '${DateFormat('dd MMM yyyy').format(res.checkin)} - ${DateFormat('dd MMM yyyy').format(res.checkout)}';
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
                                                        await ref.read(reservationNotifierProvider.notifier).checkOut(res);
                                                        if (ctx.mounted) {
                                                          Navigator.pop(ctx);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Kamar pada tanggal $dateStr berhasil diubah ke tersedia!'),
                                                              backgroundColor: AppColors.success,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      child: const Text('Hapus', style: TextStyle(color: Colors.white, fontSize: 12)),
                                                    ),
                                                  ),
                                                );
                                              }),
                                              if (roomReservations.isEmpty)
                                                ListTile(
                                                  title: const Text('Tidak ada tanggal terisi yang aktif.'),
                                                  trailing: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                                    onPressed: () async {
                                                      await ref.read(reservationNotifierProvider.notifier).setRoomTersedia(room.id);
                                                      if (ctx.mounted) {
                                                        Navigator.pop(ctx);
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(
                                                            content: Text('Kamar berhasil diubah ke tersedia!'),
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
                                              context.push('/reservations/add',
                                                  extra: {'roomId': room.id, 'roomNumber': room.nama});
                                            },
                                            child: const Text('Tambah Reservasi Baru'),
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
                            onTap: () => _showDeleteRoomDialog(context, ref, room),
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
        onPressed: () => _showAddRoomDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteRoomDialog(BuildContext context, WidgetRef ref, RoomModel room) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kamar'),
        content: Text('Yakin ingin menghapus kamar "${room.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref
                  .read(reservationNotifierProvider.notifier)
                  .deleteRoom(room.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Kamar "${room.nama}" berhasil dihapus'),
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

  void _showAddRoomDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final priceWeeklyCtrl = TextEditingController();
    final priceMonthlyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Kamar'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Kamar')),
              const SizedBox(height: 8),
              TextField(controller: typeCtrl,
                  decoration: const InputDecoration(labelText: 'Tipe Kamar (opsional)')),
              const SizedBox(height: 8),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga Harian (per malam)')),
              const SizedBox(height: 8),
              TextField(controller: priceWeeklyCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga Mingguan')),
              const SizedBox(height: 8),
              TextField(controller: priceMonthlyCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga Bulanan')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                final room = RoomModel(
                  id: '',
                  nama: nameCtrl.text.trim(),
                  harga: double.tryParse(priceCtrl.text) ?? 0,
                  hargaMingguan: double.tryParse(priceWeeklyCtrl.text) ?? 0,
                  hargaBulanan: double.tryParse(priceMonthlyCtrl.text) ?? 0,
                  status: 'tersedia',
                  tipe: typeCtrl.text.trim(),
                );
                await ref.read(reservationNotifierProvider.notifier).addRoom(room);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
