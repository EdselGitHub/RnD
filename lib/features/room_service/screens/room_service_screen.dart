import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/room_service_provider.dart';
import '../../../features/reservation/providers/reservation_provider.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/stat_card.dart';
import '../../../core/constants/app_constants.dart';
import 'add_schedule_screen.dart';

class RoomServiceScreen extends ConsumerWidget {
  const RoomServiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(roomServicesStreamProvider);
    final roomsAsync = ref.watch(roomsStreamProvider);
    final df = DateFormat('dd MMM yyyy • HH:mm', 'id_ID');

    return Scaffold(
      appBar: AppBar(title: const Text('Room Service')),
      drawer: const AppDrawer(),
      body: schedulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (schedules) {
          if (schedules.isEmpty) {
            return const EmptyState(
                message: 'Belum ada jadwal room service',
                icon: Icons.cleaning_services_outlined);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: schedules.length,
            itemBuilder: (_, i) {
              final s = schedules[i];
              final isSelesai = s.status == AppStrings.rsDone;
              final isProses = s.status == AppStrings.rsProses;
              String roomName = s.roomNumber;
              if (roomName.isEmpty && roomsAsync.value != null) {
                try {
                  final room = roomsAsync.value!.firstWhere((r) => r.id == s.roomId);
                  roomName = room.nama;
                } catch (_) {}
              }
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isSelesai
                          ? AppColors.success.withOpacity(0.12)
                          : isProses
                              ? AppColors.warning.withOpacity(0.12)
                              : AppColors.info.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    child: Icon(
                      isSelesai
                          ? Icons.check_circle_rounded
                          : isProses
                              ? Icons.cleaning_services_rounded
                              : Icons.schedule_rounded,
                      color: isSelesai
                          ? AppColors.success
                          : isProses
                              ? AppColors.warning
                              : AppColors.info,
                    ),
                  ),
                  title: Text(roomName.isNotEmpty ? 'Cleaning Kamar $roomName' : 'Cleaning #${s.id.substring(0, 6)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jadwal: ${df.format(s.jadwal)}'),
                      if (s.deskripsi.isNotEmpty)
                        Text('Deskripsi: ${s.deskripsi}',
                            style: const TextStyle(fontSize: 12)),
                      Text('Dibuat: ${df.format(s.pembuatan)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    ],
                  ),
                  trailing: isSelesai
                      ? const StatusBadge(
                          label: 'Selesai', color: AppColors.success)
                      : isProses
                          ? TextButton(
                              onPressed: () async {
                                await ref
                                    .read(roomServiceNotifierProvider.notifier)
                                    .markDone(s.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Room service selesai!'),
                                        backgroundColor: AppColors.success),
                                  );
                                }
                              },
                              child: const Text('Selesai'),
                            )
                          : TextButton(
                              onPressed: () async {
                                await ref
                                    .read(roomServiceNotifierProvider.notifier)
                                    .markProses(s.id);
                              },
                              child: const Text('Proses'),
                            ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddScheduleScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
