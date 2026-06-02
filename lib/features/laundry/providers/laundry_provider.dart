import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/laundry_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';

final laundryStreamProvider = StreamProvider<List<LaundryModel>>((ref) {
  final db = ref.watch(firestoreServiceProvider).db;
  bool isFirstSnapshot = true;
  // Menyimpan waktu kapan dokumen pertama kali muncul di stream (real-time)
  final Map<String, DateTime> realtimeAddedAt = {};

  return db
      .collection('Laundry')
      .snapshots()
      .map((snap) {
        final now = DateTime.now();

        if (!isFirstSnapshot) {
          // Real-time update: catat kapan dokumen BARU pertama kali terdeteksi
          // Ini berlaku untuk dokumen dari app manapun (user app, admin app, dll)
          for (final change in snap.docChanges) {
            if (change.type == DocumentChangeType.added) {
              realtimeAddedAt.putIfAbsent(change.doc.id, () => now);
            }
          }
        }
        isFirstSnapshot = false;

        // Parse setiap dokumen secara individual — jika satu gagal, skip saja
        final list = snap.docs
            .map((d) {
              try {
                return LaundryModel.fromDoc(d);
              } catch (_) {
                return null;
              }
            })
            .whereType<LaundryModel>()
            .toList();

        list.sort((a, b) {
          // Prioritas 1: waktu real-time (dokumen yang baru muncul saat app berjalan)
          final aRealtime = realtimeAddedAt[a.id];
          final bRealtime = realtimeAddedAt[b.id];

          final aTime = aRealtime ??
              (a.createdAt.millisecondsSinceEpoch > 0
                  ? a.createdAt
                  : DateTime.fromMillisecondsSinceEpoch(0));
          final bTime = bRealtime ??
              (b.createdAt.millisecondsSinceEpoch > 0
                  ? b.createdAt
                  : DateTime.fromMillisecondsSinceEpoch(0));

          if (aTime.millisecondsSinceEpoch != bTime.millisecondsSinceEpoch) {
            return bTime.compareTo(aTime);
          }
          // Tiebreaker: doc ID descending
          return b.id.compareTo(a.id);
        });

        return list;
      });
});

final laundryGuestNameProvider = FutureProvider.family<String, String>((ref, tamuId) async {
  if (tamuId.isEmpty) return '';
  final db = ref.watch(firestoreServiceProvider).db;
  
  try {
    final tamuDoc = await db.collection('Tamu').doc(tamuId).get();
    if (tamuDoc.exists) {
      final data = tamuDoc.data();
      if (data != null && data['nama'] != null) {
        return data['nama'] as String;
      }
    }
  } catch (_) {}

  try {
    final userDoc = await db.collection('users').doc(tamuId).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null) {
        return (data['name'] ?? data['nama'] ?? '') as String;
      }
    }
  } catch (_) {}

  return '';
});

class LaundryNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addOrder({
    required String guestName,
    String? guestPhone,
    String? guestIdNumber,
    required String roomNumber,
    required String serviceType,
    required double weight,
    double hargaPerKG = 15000,
  }) async {
    final db = ref.read(firestoreServiceProvider).db;
    final harga = weight * hargaPerKG;

    // Save guest to Tamu collection first
    final guestRef = await db.collection('Tamu').add({
      'nama': guestName,
      'no_hp': guestPhone ?? '',
    });

    // Save laundry order to Laundry collection
    await db.collection('Laundry').add({
      'tamu_id': db.collection('Tamu').doc(guestRef.id),
      'beratKG': weight,
      'harga': harga,
      'hargaPerKG': hargaPerKG,
      'jenis': serviceType,
      'status': 'menunggu',
      'no_kamar': roomNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Finance record in Transaksi_Keuangan
    await db.collection('Transaksi_Keuangan').add({
      'kategori': 'laundry',
      'deskripsi': 'Laundry Room $roomNumber ($serviceType - ${weight}KG)',
      'jumlah': harga,
      'tanggal': Timestamp.fromDate(DateTime.now()),
      'tipe': 'income',
    });
  }


  Future<void> updateStatus(String id, String newStatus) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection('Laundry').doc(id).update({'status': newStatus});
  }

  Future<void> markDone(String id) async {
    await updateStatus(id, 'selesai');
  }

  Future<void> markProses(String id) async {
    await updateStatus(id, 'proses');
  }
}

final laundryNotifierProvider =
    AsyncNotifierProvider<LaundryNotifier, void>(() => LaundryNotifier());
