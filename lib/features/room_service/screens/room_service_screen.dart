import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/room_service_provider.dart';
import '../../../features/reservation/providers/reservation_provider.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/stat_card.dart';
import '../../../core/constants/app_constants.dart';

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
              final isSelesai = s.status == 'selesai';
              final isProses = s.status == 'proses';
              final roomName = roomsAsync.maybeWhen(
                data: (rooms) {
                  try {
                    return rooms.firstWhere((r) => r.id == s.roomId).nama;
                  } catch (_) {
                    return s.id.substring(0, 6);
                  }
                },
                orElse: () => s.id.substring(0, 6),
              );
              
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
                  title: Text(
                    roomName.length > 6 && !roomName.toLowerCase().startsWith('room') 
                        ? 'Cleaning $roomName'
                        : 'Cleaning Room $roomName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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

class AddScheduleScreen extends ConsumerStatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  ConsumerState<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends ConsumerState<AddScheduleScreen> {
  String? _selectedRoomId;
  String? _selectedRoomNumber;
  DateTime? _scheduledAt;
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRoomId == null || _scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kamar dan waktu jadwal')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(roomServiceNotifierProvider.notifier).addSchedule(
            roomId: _selectedRoomId!,
            roomNumber: _selectedRoomNumber!,
            scheduledAt: _scheduledAt!,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Jadwal berhasil ditambahkan!'),
            backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsStreamProvider);
    final df = DateFormat('dd MMM yyyy • HH:mm', 'id_ID');

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Room Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room selector
                roomsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (rooms) => DropdownButtonFormField<String>(
                    value: _selectedRoomId,
                    decoration: const InputDecoration(labelText: 'Pilih Kamar'),
                    items: rooms
                        .map((r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(r.nama),
                            ))
                        .toList(),
                    onChanged: (id) {
                      final room = rooms.firstWhere((r) => r.id == id);
                      setState(() {
                        _selectedRoomId = id;
                        _selectedRoomNumber = room.nama;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // DateTime picker
                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final date = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 30)));
                    if (date != null && context.mounted) {
                      final time = await showTimePicker(
                          context: context, initialTime: TimeOfDay.now());
                      if (time != null) {
                        setState(() => _scheduledAt = DateTime(
                            date.year, date.month, date.day,
                            time.hour, time.minute));
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          _scheduledAt != null
                              ? df.format(_scheduledAt!)
                              : 'Pilih Tanggal & Waktu',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Deskripsi (opsional)',
                      prefixIcon: Icon(Icons.note_outlined)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Simpan Jadwal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
