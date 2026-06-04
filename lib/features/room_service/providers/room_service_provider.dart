import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/room_service_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/services/notification_sound_service.dart';
import '../../../core/constants/firestore_constants.dart';

final roomServicesStreamProvider =
    StreamProvider<List<RoomServiceModel>>((ref) {
  final db = ref.watch(firestoreServiceProvider).db;
  bool isInitial = true;
  return db
      .collection(FirestoreCollections.cleaningRoom)
      .snapshots()
      .map((snap) {
    if (!isInitial) {
      for (var change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          NotificationSoundService.playNotificationSound();
          break; // Mainkan sekali per batch
        }
      }
    }
    isInitial = false;
    final list = snap.docs.map((d) => RoomServiceModel.fromDoc(d)).toList();
    // Sort terbaru di atas — gunakan createdAt (alias pembuatan) dengan fallback ke doc ID
    list.sort((a, b) {
      final aTime = a.createdAt.millisecondsSinceEpoch;
      final bTime = b.createdAt.millisecondsSinceEpoch;
      if (aTime == 0 && bTime == 0) {
        return b.id.compareTo(a.id);
      }
      return bTime.compareTo(aTime);
    });
    return list;
  });
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

    await db.collection(FirestoreCollections.cleaningRoom).add({
      'room_id': db.collection(FirestoreCollections.ruangan).doc(roomId),
      'room_number': roomNumber,
      'deskripsi': notes ?? '',
      'jadwal': Timestamp.fromDate(scheduledAt),
      'pembuatan': FieldValue.serverTimestamp(),
      'status': 'menunggu',
    });
  }

  Future<void> updateStatus(String id, String newStatus) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection(FirestoreCollections.cleaningRoom).doc(id).update({'status': newStatus});
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
