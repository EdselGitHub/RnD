import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/room_service_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/services/notification_sound_service.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/app_constants.dart';

//FUNGSI untuk  membaca database firestore agar aktif sound ketika snapshot.added
final roomServicesStreamProvider =
    StreamProvider<List<RoomServiceModel>>((ref) async* { //async / stream generator realtime
  final db = ref.watch(firestoreServiceProvider).db; // memantau / mendengarkan secara aktif
  bool isInitial = true;
  final snapshots = db.collection(FirestoreCollections.cleaningRoom).snapshots(); //koneksi realtime ke firestore, setiap kali ada perubahan akan mengirimkan snapshot data terbaru yaitu snap

  await for (final snap in snapshots) { //loop yang berjalan ketika ada data masuk (snap)
    if (!isInitial) { //cek apakah snapshot diterima adalah data utama saat apliaksi dibuka
      for (var change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) { //added, modified, removed
          NotificationSoundService.playNotificationSound();
          break; //mainkan sound hanya sekali 
        }
      }
    }
    isInitial = false;

    //FUNGSI mengurut data terbaru berada di paling atas
    final List<RoomServiceModel> list = [];
    for (final d in snap.docs) {
      list.add(RoomServiceModel.fromDoc(d)); //mengubah data dari doc snapshot ke model RoomServiceModel
    }

    //sort terbaru di atas menggunakan createdAt (pembuatan) dengan fallback ke doc ID
    list.sort((a, b) {
      final aTime = a.createdAt.millisecondsSinceEpoch;
      final bTime = b.createdAt.millisecondsSinceEpoch;
      if (aTime == 0 && bTime == 0) { //jika kedua createdAt adalah 0 (data lama) maka urutkan berdasarkan ID
        return b.id.compareTo(a.id); //urutkan berdasarkan ID
      }
      return bTime.compareTo(aTime); //jika tidak maka urutkan berdasarkan createdAt
    });

    yield list; //mengirim daftar yang terurut / yield mastiin ui yang liat provider supaya update otomatis kalau ada perubahan data di database
  }
});

//class menambah jadwal baru dan mengubah status pesanan
class RoomServiceNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {} //kosong untuk input database

  //FUGNSI menambah jadwal pembersihan ke database
  Future<void> addSchedule({
    required String roomId,
    required String roomNumber,
    required DateTime scheduledAt,
    String? notes,
  }) async {
    final db = ref.read(firestoreServiceProvider).db; //mengambil instance firebase firestore / satu kali aksi (ref.read)

    await db.collection(FirestoreCollections.cleaningRoom).add({ //await supaya nunggu data yang dikirim ke database masuk baru proses ui done
      'room_id': db.collection(FirestoreCollections.ruangan).doc(roomId),
      'room_number': roomNumber,
      'deskripsi': notes ?? '',
      'jadwal': Timestamp.fromDate(scheduledAt),
      'pembuatan': FieldValue.serverTimestamp(),
      'status': AppStrings.rsWaiting,
    });
  }

  //void = tidak mengembalikan nilai (return) contoh string, boolean /int
  //async berarti butuh waktu untuk kirim data 

  //FUNGSI mengubah status pemesanan menjadi selesai atau proses
  Future<void> updateStatus(String id, String newStatus) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection(FirestoreCollections.cleaningRoom).doc(id).update({'status': newStatus});
  }

  Future<void> markDone(String id) async {
    await updateStatus(id, AppStrings.rsDone);
  }

  Future<void> markProses(String id) async {
    await updateStatus(id, AppStrings.rsProses);
  }
}

//penyedia / provider supaya roomServiceNotifier bisa dipanggil di semua bagian aplikasi
final roomServiceNotifierProvider =
    AsyncNotifierProvider<RoomServiceNotifier, void>(
        () => RoomServiceNotifier());
