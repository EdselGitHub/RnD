import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/motorcycle_model.dart';
import '../../../core/models/motor_rental_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/constants/firestore_constants.dart';

final motorcyclesStreamProvider = StreamProvider<List<MotorcycleModel>>((ref) async* {
  final db = ref.watch(firestoreServiceProvider).db;
  final rentalsAsync = ref.watch(motorRentalsStreamProvider);

  final motorsStream = db.collection(FirestoreCollections.motor).orderBy('nama').snapshots();

  await for (final snap in motorsStream) {
    // 1. Mengambil data motor yang tidak dihapus menggunakan loop for biasa
    final List<MotorcycleModel> motorsList = [];
    for (final d in snap.docs) {
      final motor = MotorcycleModel.fromDoc(d);
      if (motor.status != 'dihapus') {
        motorsList.add(motor);
      }
    }

    final List<MotorcycleModel> finalMotors = [];

    if (rentalsAsync is AsyncData) {
      final rentals = rentalsAsync.value!;
      final now = DateTime.now();

      // 2. Mengecek status rental menggunakan loop for biasa
      for (final motor in motorsList) {
        if (motor.status == 'maintenance') {
          finalMotors.add(motor);
          continue;
        }

        bool isOccupiedNow = false;
        for (final res in rentals) {
          if (res.status == 'aktif' &&
              res.motorId == motor.id &&
              now.compareTo(res.tanggal) >= 0 &&
              now.compareTo(res.tanggalSelesai) < 0) {
            isOccupiedNow = true;
            break; // Jika sudah cocok, hentikan pencarian
          }
        }

        finalMotors.add(MotorcycleModel(
          id: motor.id,
          nama: motor.nama,
          harga: motor.harga,
          status: isOccupiedNow ? 'disewa' : 'tersedia',
        ));
      }
    } else {
      finalMotors.addAll(motorsList);
    }
    yield finalMotors;
  }
});

final motorRentalsStreamProvider =
    StreamProvider<List<MotorRentalModel>>((ref) async* {
  final db = ref.watch(firestoreServiceProvider).db;
  final snapshots = db
      .collection(FirestoreCollections.motorSewa)
      .orderBy('pembuatan', descending: true)
      .snapshots();

  await for (final snap in snapshots) {
    final List<MotorRentalModel> list = [];
    for (final d in snap.docs) {
      list.add(MotorRentalModel.fromDoc(d));
    }
    yield list;
  }
});

class MotorNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addRental({
    required MotorcycleModel motorcycle,
    required String guestName,
    required String guestPhone,
    required String unit,
    required DateTime startDate,
    required DateTime endDate,
    required double total,
  }) async {
    final db = ref.read(firestoreServiceProvider).db;

    // Save guest to Tamu collection
    final guestRef = await db.collection(FirestoreCollections.tamu).add({
      'nama': guestName,
      'no_hp': guestPhone,
      'kartu_identitas': '',
    });

    // Save rental to Motor_Sewa collection
    await db.collection(FirestoreCollections.motorSewa).add({
      'motor_id': db.collection(FirestoreCollections.motor).doc(motorcycle.id),
      'tamu_id': db.collection(FirestoreCollections.tamu).doc(guestRef.id),
      'harga_perhari': motorcycle.harga,
      'status': 'aktif',
      'tanggal': Timestamp.fromDate(startDate),
      'tanggal_selesai': Timestamp.fromDate(endDate),
      'pembuatan': Timestamp.fromDate(DateTime.now()),
      'total': total,
      'unit': unit,
    });

    // Update motor status
    await db.collection(FirestoreCollections.motor).doc(motorcycle.id).update({'status': 'disewa'});

    // Finance record in Transaksi_Keuangan
    await db.collection(FirestoreCollections.transaksiKeuangan).add({
      'kategori': 'motor',
      'deskripsi': 'Sewa motor ${motorcycle.nama} (Unit $unit)',
      'jumlah': total,
      'tanggal': Timestamp.fromDate(DateTime.now()),
      'tipe': 'income',
    });
  }

  Future<void> returnMotor(MotorRentalModel rental) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection(FirestoreCollections.motorSewa).doc(rental.id).update({'status': 'selesai'});
    await db.collection(FirestoreCollections.motor).doc(rental.motorId).update({'status': 'tersedia'});
  }


  /// Set motor status langsung ke 'tersedia' dari daftar motor
  Future<void> setMotorTersedia(String motorId) async {
    final db = ref.read(firestoreServiceProvider).db;
    
    // Ubah status sewa yang aktif menjadi selesai agar stream tidak mengubahnya kembali menjadi 'disewa'
    final rentalsSnap = await db.collection(FirestoreCollections.motorSewa).where('status', isEqualTo: 'aktif').get();
    for (final doc in rentalsSnap.docs) {
      final data = doc.data();
      final refId = data['motor_id'] is DocumentReference 
          ? (data['motor_id'] as DocumentReference).id 
          : data['motor_id'] as String? ?? '';
      if (refId == motorId) {
        await db.collection(FirestoreCollections.motorSewa).doc(doc.id).update({'status': 'selesai'});
      }
    }

    await db.collection(FirestoreCollections.motor).doc(motorId).update({'status': 'tersedia'});
  }

  Future<void> addMotorcycle(MotorcycleModel motorcycle) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection(FirestoreCollections.motor).add(motorcycle.toMap());
  }

  /// Hapus motor secara soft-delete
  Future<void> deleteMotor(String motorId) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection(FirestoreCollections.motor).doc(motorId).update({'status': 'dihapus'});
  }
}

final motorNotifierProvider =
    AsyncNotifierProvider<MotorNotifier, void>(() => MotorNotifier());
