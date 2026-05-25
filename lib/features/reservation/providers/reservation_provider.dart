import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/reservation_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/guest_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';

final roomsStreamProvider = StreamProvider<List<RoomModel>>((ref) async* {
  final db = ref.watch(firestoreServiceProvider).db;
  final reservationsAsync = ref.watch(reservationsStreamProvider);

  final roomsStream = db.collection('Ruangan').orderBy('nama').snapshots();

  await for (final snap in roomsStream) {
    var rooms = snap.docs
        .map((d) => RoomModel.fromDoc(d))
        .where((r) => r.status != 'dihapus')
        .toList();

    if (reservationsAsync is AsyncData) {
      final reservations = reservationsAsync.value!;
      final now = DateTime.now();

      rooms = rooms.map((room) {
        if (room.status == 'maintenance') return room;

        bool isOccupiedNow = reservations.any((res) {
          if (res.status != 'aktif') return false;
          if (res.roomId != room.id) return false;
          return now.compareTo(res.checkin) >= 0 && now.compareTo(res.checkout) < 0;
        });

        return RoomModel(
          id: room.id,
          nama: room.nama,
          harga: room.harga,
          hargaMingguan: room.hargaMingguan,
          hargaBulanan: room.hargaBulanan,
          status: isOccupiedNow ? 'tidak tersedia' : 'tersedia',
        );
      }).toList();
    }
    yield rooms;
  }
});

final reservationsStreamProvider =
    StreamProvider<List<ReservationModel>>((ref) {
  final db = ref.watch(firestoreServiceProvider).db;
  return db
      .collection('Reservasi')
      .orderBy('checkin', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => ReservationModel.fromDoc(d)).toList());
});

class ReservationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addReservation({
    required RoomModel room,
    required GuestModel guest,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    final db = ref.read(firestoreServiceProvider).db;

    final nights = checkOut.difference(checkIn).inDays;
    
    double total = 0;
    int remainingNights = nights;

    if (room.hargaBulanan > 0 && remainingNights >= 30) {
      final months = remainingNights ~/ 30;
      total += months * room.hargaBulanan;
      remainingNights %= 30;
    }

    if (room.hargaMingguan > 0 && remainingNights >= 7) {
      final weeks = remainingNights ~/ 7;
      total += weeks * room.hargaMingguan;
      remainingNights %= 7;
    }

    total += remainingNights * room.harga;

    // Save guest to Tamu collection (URL sudah dari Cloudinary)
    final guestMap = guest.toMap();
    final guestRef = await db.collection('Tamu').add(guestMap);

    // Save reservation to Reservasi collection with DocumentReference
    await db.collection('Reservasi').add({
      'room_id': db.collection('Ruangan').doc(room.id),
      'tamu_id': db.collection('Tamu').doc(guestRef.id),
      'checkin': Timestamp.fromDate(checkIn),
      'checkout': Timestamp.fromDate(checkOut),
      'total': total,
      'status': 'aktif',
    });

    // Update room status
    await db.collection('Ruangan').doc(room.id).update({'status': 'tidak tersedia'});

    // Record finance in Transaksi_Keuangan
    await db.collection('Transaksi_Keuangan').add({
      'kategori': 'penjualan kamar',
      'deskripsi': 'Penjualan kamar ${room.nama}',
      'jumlah': total,
      'tanggal': Timestamp.fromDate(DateTime.now()),
      'tipe': 'income',
    });
  }

  Future<void> checkOut(ReservationModel reservation) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db
        .collection('Reservasi')
        .doc(reservation.id)
        .update({'status': 'selesai'});
    await db
        .collection('Ruangan')
        .doc(reservation.roomId)
        .update({'status': 'tersedia'});
  }


  Future<void> addRoom(RoomModel room) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection('Ruangan').add(room.toMap());
  }

  /// Set room status langsung ke 'tersedia' dari daftar kamar
  Future<void> setRoomTersedia(String roomId) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection('Ruangan').doc(roomId).update({'status': 'tersedia'});
  }

  /// Hapus kamar secara soft-delete agar laporan keuangan tidak terpengaruh
  Future<void> deleteRoom(String roomId) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection('Ruangan').doc(roomId).update({'status': 'dihapus'});
  }
}

final reservationNotifierProvider =
    AsyncNotifierProvider<ReservationNotifier, void>(
        () => ReservationNotifier());
