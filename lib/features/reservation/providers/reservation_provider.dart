import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/reservation_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/guest_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/constants/firestore_constants.dart';

final roomsStreamProvider = StreamProvider<List<RoomModel>>((ref) async* {
  final db = ref.watch(firestoreServiceProvider).db;
  final reservationsAsync = ref.watch(reservationsStreamProvider);

  final roomsStream = db.collection(FirestoreCollections.ruangan).orderBy('nama').snapshots();

  await for (final snap in roomsStream) {
    // 1. Mengambil data ruangan yang tidak dihapus menggunakan loop for biasa
    final List<RoomModel> roomsList = [];
    for (final d in snap.docs) {
      final room = RoomModel.fromDoc(d);
      if (room.status != 'dihapus') {
        roomsList.add(room);
      }
    }

    final List<RoomModel> finalRooms = [];

    if (reservationsAsync is AsyncData) {
      final reservations = reservationsAsync.value!;
      final now = DateTime.now();

      // 2. Mengecek status okupansi menggunakan loop for biasa
      for (final room in roomsList) {
        bool isOccupiedNow = false;
        
        for (final res in reservations) {
          if (res.status == 'aktif' &&
              res.roomId == room.id &&
              now.compareTo(res.checkin) >= 0 &&
              now.compareTo(res.checkout) < 0) {
            isOccupiedNow = true;
            break; // Jika sudah cocok, hentikan pencarian
          }
        }

        finalRooms.add(RoomModel(
          id: room.id,
          nama: room.nama,
          harga: room.harga,
          hargaMingguan: room.hargaMingguan,
          hargaBulanan: room.hargaBulanan,
          status: isOccupiedNow ? 'tidak tersedia' : 'tersedia',
        ));
      }
    } else {
      finalRooms.addAll(roomsList);
    }
    
    yield finalRooms;
  }
});

final reservationsStreamProvider =
    StreamProvider<List<ReservationModel>>((ref) async* {
  final db = ref.watch(firestoreServiceProvider).db;
  final snapshots = db
      .collection(FirestoreCollections.reservasi)
      .orderBy('checkin', descending: true)
      .snapshots();

  await for (final snap in snapshots) {
    final List<ReservationModel> list = [];
    for (final d in snap.docs) {
      list.add(ReservationModel.fromDoc(d));
    }
    yield list;
  }
});

class ReservationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addReservation({
    required RoomModel room,
    required GuestModel guest,
    required DateTime checkIn,
    required DateTime checkOut,
    required double total,
  }) async {
    final db = ref.read(firestoreServiceProvider).db;

    // simpan guest ke Tamu collection
    final guestMap = guest.toMap();
    final guestRef = await db.collection(FirestoreCollections.tamu).add(guestMap);

    // simpan reservasi ke Reservasi collection dengan DocumentReference
    await db.collection(FirestoreCollections.reservasi).add({
      'room_id': db.collection(FirestoreCollections.ruangan).doc(room.id),
      'tamu_id': db.collection(FirestoreCollections.tamu).doc(guestRef.id),
      'checkin': Timestamp.fromDate(checkIn),
      'checkout': Timestamp.fromDate(checkOut),
      'total': total,
      'status': 'aktif',
    });

    //update room status
    await db.collection(FirestoreCollections.ruangan).doc(room.id).update({'status': 'tidak tersedia'});

    // record finance di Transaksi_Keuangan
    await db.collection(FirestoreCollections.transaksiKeuangan).add({
      'kategori': 'penjualan kamar',
      'deskripsi': 'Penjualan kamar ${room.nama}',
      'jumlah': total,
      'tanggal': Timestamp.fromDate(DateTime.now()),
      'tipe': 'income',
      'kartu_identitas': guest.kartuIdentitas, //simpan referensi KTP
    });
  }

  Future<void> checkOut(ReservationModel reservation) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db
        .collection(FirestoreCollections.reservasi)
        .doc(reservation.id)
        .update({'status': 'selesai'});
    await db
        .collection(FirestoreCollections.ruangan)
        .doc(reservation.roomId)
        .update({'status': 'tersedia'});
  }


  Future<void> addRoom(RoomModel room) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection(FirestoreCollections.ruangan).add(room.toMap());
  }

  // set room status langsung ke 'tersedia' dari daftar kamar
  Future<void> setRoomTersedia(String roomId) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection(FirestoreCollections.ruangan).doc(roomId).update({'status': 'tersedia'});
  }

  // hapus kamar secara soft delete agar laporan keuangan tidak terpengaruh
  Future<void> deleteRoom(String roomId) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection(FirestoreCollections.ruangan).doc(roomId).update({'status': 'dihapus'});
  }
}

final reservationNotifierProvider =
    AsyncNotifierProvider<ReservationNotifier, void>(
        () => ReservationNotifier());
