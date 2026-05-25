import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/motorcycle_model.dart';
import '../../../core/models/motor_rental_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';

final motorcyclesStreamProvider = StreamProvider<List<MotorcycleModel>>((ref) async* {
  final db = ref.watch(firestoreServiceProvider).db;
  final rentalsAsync = ref.watch(motorRentalsStreamProvider);

  final motorsStream = db.collection('Motor').orderBy('nama').snapshots();

  await for (final snap in motorsStream) {
    var motors = snap.docs
        .map((d) => MotorcycleModel.fromDoc(d))
        .where((m) => m.status != 'dihapus')
        .toList();

    if (rentalsAsync is AsyncData) {
      final rentals = rentalsAsync.value!;
      final now = DateTime.now();

      motors = motors.map((motor) {
        if (motor.status == 'maintenance') return motor;

        bool isOccupiedNow = rentals.any((res) {
          if (res.status != 'aktif') return false;
          if (res.motorId != motor.id) return false;
          return now.compareTo(res.tanggal) >= 0 && now.compareTo(res.tanggalSelesai) < 0;
        });

        return MotorcycleModel(
          id: motor.id,
          nama: motor.nama,
          harga: motor.harga,
          status: isOccupiedNow ? 'disewa' : 'tersedia',
        );
      }).toList();
    }
    yield motors;
  }
});

final motorRentalsStreamProvider =
    StreamProvider<List<MotorRentalModel>>((ref) {
  final db = ref.watch(firestoreServiceProvider).db;
  return db
      .collection('Motor_Sewa')
      .orderBy('pembuatan', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => MotorRentalModel.fromDoc(d)).toList());
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
  }) async {
    final db = ref.read(firestoreServiceProvider).db;
    final days = endDate.difference(startDate).inDays;
    final hargaPerhari = 150000.0;
    final total = hargaPerhari * days;

    // Save guest to Tamu collection
    final guestRef = await db.collection('Tamu').add({
      'nama': guestName,
      'no_hp': guestPhone,
      'kartu_identitas': '',
    });

    // Save rental to Motor_Sewa collection
    await db.collection('Motor_Sewa').add({
      'motor_id': db.collection('Motor').doc(motorcycle.id),
      'tamu_id': db.collection('Tamu').doc(guestRef.id),
      'harga_perhari': hargaPerhari,
      'status': 'aktif',
      'tanggal': Timestamp.fromDate(startDate),
      'tanggal_selesai': Timestamp.fromDate(endDate),
      'pembuatan': Timestamp.fromDate(DateTime.now()),
      'total': total,
      'unit': unit,
    });

    // Update motor status
    await db.collection('Motor').doc(motorcycle.id).update({'status': 'disewa'});

    // Finance record in Transaksi_Keuangan
    await db.collection('Transaksi_Keuangan').add({
      'kategori': 'motor',
      'deskripsi': 'Sewa motor ${motorcycle.nama} (Unit $unit)',
      'jumlah': total,
      'tanggal': Timestamp.fromDate(DateTime.now()),
      'tipe': 'income',
    });
  }

  Future<void> returnMotor(MotorRentalModel rental) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection('Motor_Sewa').doc(rental.id).update({'status': 'selesai'});
    await db.collection('Motor').doc(rental.motorId).update({'status': 'tersedia'});
  }


  /// Set motor status langsung ke 'tersedia' dari daftar motor
  Future<void> setMotorTersedia(String motorId) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection('Motor').doc(motorId).update({'status': 'tersedia'});
  }

  Future<void> addMotorcycle(MotorcycleModel motorcycle) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection('Motor').add(motorcycle.toMap());
  }

  /// Hapus motor secara soft-delete
  Future<void> deleteMotor(String motorId) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection('Motor').doc(motorId).update({'status': 'dihapus'});
  }
}

final motorNotifierProvider =
    AsyncNotifierProvider<MotorNotifier, void>(() => MotorNotifier());
