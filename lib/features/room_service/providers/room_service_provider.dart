import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/room_service_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';

final roomServicesStreamProvider =
    StreamProvider<List<RoomServiceModel>>((ref) {
  final db = ref.watch(firestoreServiceProvider).db;
  return db
      .collection('CleaningRoom')
      .orderBy('jadwal', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => RoomServiceModel.fromDoc(d)).toList());
});

class RoomServiceNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addSchedule({
    required String roomId,
    required String roomNumber,
    required DateTime scheduledAt,
    String? assignedTo,
    String? notes,
  }) async {
    final db = ref.read(firestoreServiceProvider).db;
    final now = DateTime.now();

    await db.collection('CleaningRoom').add({
      'room_id': db.collection('Ruangan').doc(roomId),
      'deskripsi': notes ?? '',
      'jadwal': Timestamp.fromDate(scheduledAt),
      'pembuatan': Timestamp.fromDate(now),
      'status': 'menunggu',
    });
  }

  Future<void> updateStatus(String id, String newStatus) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection('CleaningRoom').doc(id).update({'status': newStatus});
  }

  Future<void> markDone(String id) async {
    await updateStatus(id, 'selesai');
  }

  Future<void> markProses(String id) async {
    await updateStatus(id, 'proses');
  }
}

final roomServiceNotifierProvider =
    AsyncNotifierProvider<RoomServiceNotifier, void>(
        () => RoomServiceNotifier());
