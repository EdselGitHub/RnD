import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/laundry_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';

final laundryStreamProvider = StreamProvider<List<LaundryModel>>((ref) {
  final db = ref.watch(firestoreServiceProvider).db;
  return db
      .collection('Laundry')
      .snapshots()
      .map((snap) => snap.docs.map((d) => LaundryModel.fromDoc(d)).toList());
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
      'kartu_identitas': guestIdNumber ?? '',
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
