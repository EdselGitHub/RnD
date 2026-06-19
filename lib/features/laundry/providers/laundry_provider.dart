import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/laundry_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/app_constants.dart';

final laundryStreamProvider = StreamProvider<List<LaundryModel>>((ref) async* {
  final db = ref.watch(firestoreServiceProvider).db;
  bool isFirstSnapshot = true;
  // Menyimpan waktu kapan dokumen pertama kali muncul di stream (real-time)
  final Map<String, DateTime> realtimeAddedAt = {};
  final snapshots = db.collection(FirestoreCollections.laundry).snapshots();

  await for (final snap in snapshots) {
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

    //parse setiap dokumen secara individual — jika satu gagal, skip saja menggunakan loop
    final List<LaundryModel> list = [];
    for (final d in snap.docs) {
      try {
        final item = LaundryModel.fromDoc(d);
        list.add(item);
      } catch (_) {
        //skip jika gagal parsing
      }
    }

    list.sort((a, b) {
      //prioritas 1: waktu real-time (dokumen yang baru muncul saat app berjalan)
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
      // tiebreaker: doc ID descending
      return b.id.compareTo(a.id);
    });

    yield list;
  }
});

final laundryGuestNameProvider = FutureProvider.family<String, String>((ref, tamuId) async {
  if (tamuId.isEmpty) return '';
  final db = ref.watch(firestoreServiceProvider).db;
  
  try {
    final tamuDoc = await db.collection(FirestoreCollections.tamu).doc(tamuId).get();
    if (tamuDoc.exists) {
      final data = tamuDoc.data();
      if (data != null && data['nama'] != null) {
        return data['nama'] as String;
      }
    }
  } catch (_) {}

  try {
    final userDoc = await db.collection(FirestoreCollections.users).doc(tamuId).get();
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

    //simpan guest ke Tamu collection
    final guestRef = await db.collection(FirestoreCollections.tamu).add({
      'nama': guestName,
      'no_hp': guestPhone ?? '',
    });

    //simpan laundru ke collection Laundry
    await db.collection(FirestoreCollections.laundry).add({
      'tamu_id': db.collection(FirestoreCollections.tamu).doc(guestRef.id),
      'beratKG': weight,
      'harga': harga,
      'hargaPerKG': hargaPerKG,
      'jenis': serviceType,
      'status': AppStrings.laundryWaiting,
      'no_kamar': roomNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });

    //finance record di Transaksi_Keuangan
    await db.collection(FirestoreCollections.transaksiKeuangan).add({
      'kategori': 'laundry',
      'deskripsi': 'Laundry Room $roomNumber ($serviceType - ${weight}KG)',
      'jumlah': harga,
      'tanggal': Timestamp.fromDate(DateTime.now()),
      'tipe': 'income',
    });
  }


  Future<void> updateStatus(String id, String newStatus) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection(FirestoreCollections.laundry).doc(id).update({'status': newStatus});
  }

  Future<void> markDone(String id) async {
    await updateStatus(id, AppStrings.laundryDone);
  }

  Future<void> markProses(String id) async {
    await updateStatus(id, AppStrings.laundryProcessing);
  }
}

final laundryNotifierProvider =
    AsyncNotifierProvider<LaundryNotifier, void>(() => LaundryNotifier());
