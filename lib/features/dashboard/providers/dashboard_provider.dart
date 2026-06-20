import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/app_constants.dart';

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

class DashboardStats {
  final int occupiedRooms;
  final int totalRooms;
  final int rentedMotors;
  final int totalMotors;
  final double todayIncome;
  final List<String> lowStockDrinks;

  const DashboardStats({
    required this.occupiedRooms,
    required this.totalRooms,
    required this.rentedMotors,
    required this.totalMotors,
    required this.todayIncome,
    required this.lowStockDrinks,
  });
}

/// auto-complete expired motor rentals di firestore.
/// jika rental is still 'aktif' tapi tanggalSelesai has passed,
/// tandai rental as 'selesai' dan motor as 'tersedia'.
Future<void> _autoCompleteExpiredRentals(
  FirebaseFirestore db,
  QuerySnapshot motorSewaSnap,
) async {
  final now = DateTime.now();
  for (final doc in motorSewaSnap.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] as String? ?? '';
    if (status != 'aktif') continue;

    final tanggalSelesai =
        (data['tanggal_selesai'] as Timestamp?)?.toDate();
    if (tanggalSelesai == null) continue;

    if (now.isAfter(tanggalSelesai)) {
      try {
        //tandai rental selesai 
        await db.collection(FirestoreCollections.motorSewa).doc(doc.id).update({
          'status': 'selesai',
        });

        //tandai motor tersedia
        final motorIdRef = data['motor_id'];
        final String motorId = motorIdRef is DocumentReference
            ? motorIdRef.id
            : (motorIdRef as String? ?? '');
        if (motorId.isNotEmpty) {
          await db.collection(FirestoreCollections.motor).doc(motorId).update({
            'status': AppStrings.motorAvailable,
          });
        }
        debugPrint(
            '[Dashboard] Complete otomatis rental selesai ${doc.id}, motor $motorId');
      } catch (e) {
        debugPrint('[Dashboard] Error complete otomatis rental ${doc.id}: $e');
      }
    }
  }
}

final dashboardStatsProvider = StreamProvider<DashboardStats>((ref) {
  final db = ref.watch(firestoreServiceProvider).db;

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final roomsStream = db.collection(FirestoreCollections.ruangan).snapshots();
  final motorsStream = db.collection(FirestoreCollections.motor).snapshots();
  final motorSewaStream = db.collection(FirestoreCollections.motorSewa).snapshots();
  final financeStream1 = db
      .collection(FirestoreCollections.transaksiKeuangan)
      .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('tanggal', isLessThan: Timestamp.fromDate(endOfDay))
      .snapshots();
  final drinksStream = db.collection(FirestoreCollections.minuman).where('stok', isLessThan: 2).snapshots();
  final reservasiStream = db.collection(FirestoreCollections.reservasi).where('status', isEqualTo: 'aktif').snapshots();

  StreamController<DashboardStats>? controller;
  
  QuerySnapshot? roomsSnap;
  QuerySnapshot? motorsSnap;
  QuerySnapshot? motorSewaSnap;
  QuerySnapshot? financeSnap1;
  QuerySnapshot? drinksSnap;
  QuerySnapshot? reservasiSnap;

  void tryEmit() {
    if (roomsSnap == null || motorsSnap == null || motorSewaSnap == null ||
        financeSnap1 == null ||
        drinksSnap == null || reservasiSnap == null) {
      return;
    }

    //auto complete rental yang expired
    _autoCompleteExpiredRentals(db, motorSewaSnap!);

    final now = DateTime.now();

    int occupiedRooms = 0;
    for (final d in roomsSnap!.docs) {
      final roomData = d.data() as Map<String, dynamic>;
      if (roomData['status'] == 'dihapus' || roomData['status'] == 'maintenance') {
        continue;
      }

      bool isOccupiedNow = false;
      for (final resDoc in reservasiSnap!.docs) {
        final resData = resDoc.data() as Map<String, dynamic>;
        
        final roomIdRef = resData['room_id'];
        final String resRoomId = roomIdRef is DocumentReference ? roomIdRef.id : (roomIdRef as String? ?? '');

        if (resRoomId == d.id) {
          final checkin = (resData['checkin'] as Timestamp?)?.toDate() ?? DateTime.now();
          final checkout = (resData['checkout'] as Timestamp?)?.toDate() ?? DateTime.now();
          
          if (now.compareTo(checkin) >= 0 && now.compareTo(checkout) < 0) {
            isOccupiedNow = true;
            break;
          }
        }
      }

      if (isOccupiedNow) {
        occupiedRooms++;
      }
    }

    //hitung kalkulasi sesuai rental tanggal 
    //logika sama dengan  motorcycle_list_screen aktif saat periode rental
    final List<DocumentSnapshot> activeMotorsDocs = [];
    for (final d in motorsSnap!.docs) {
      final motorData = d.data() as Map<String, dynamic>;
      if (motorData['status'] != AppStrings.motorDelete && motorData['status'] != 'dihapus') {
        activeMotorsDocs.add(d);
      }
    }

    int rentedMotors = 0;
    for (final motorDoc in activeMotorsDocs) {
      final motorData = motorDoc.data() as Map<String, dynamic>;

      // cek apakah motor sedang terental
      bool isRentedNow = false;
      for (final sewaDoc in motorSewaSnap!.docs) {
        final sewaData = sewaDoc.data() as Map<String, dynamic>;
        final sewaStatus = sewaData['status'] as String? ?? '';
        if (sewaStatus != 'aktif') continue;

        final motorIdRef = sewaData['motor_id'];
        final String sewaMotorId = motorIdRef is DocumentReference
            ? motorIdRef.id
            : (motorIdRef as String? ?? '');
        if (sewaMotorId != motorDoc.id) continue;

        final tanggal =
            (sewaData['tanggal'] as Timestamp?)?.toDate();
        final tanggalSelesai =
            (sewaData['tanggal_selesai'] as Timestamp?)?.toDate();
        
        if (tanggal == null) continue;

        if (tanggalSelesai == null) {
          if (now.compareTo(tanggal) >= 0) {
            isRentedNow = true;
            break;
          }
        } else {
          if (now.compareTo(tanggal) >= 0 && now.compareTo(tanggalSelesai) < 0) {
            isRentedNow = true;
            break;
          }
        }
      }

      if (isRentedNow) rentedMotors++;
    }

    double todayIncome = 0;
    for (final doc in financeSnap1!.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['jumlah'] as num).toDouble();
      if (data['tipe'] == 'expense') {
        todayIncome -= amount;
      } else {
        todayIncome += amount;
      }
    }

    final List<String> lowStockDrinks = [];
    for (final d in drinksSnap!.docs) {
      final drinkName = (d.data() as Map<String, dynamic>)['nama'] as String? ?? '';
      lowStockDrinks.add(drinkName);
    }

    int activeRoomsCount = 0;
    for (final d in roomsSnap!.docs) {
      final roomData = d.data() as Map<String, dynamic>;
      if (roomData['status'] != 'dihapus') {
        activeRoomsCount++;
      }
    }

    final activeMotorsCount = activeMotorsDocs.length;

    controller?.add(DashboardStats(
      occupiedRooms: occupiedRooms,
      totalRooms: activeRoomsCount,
      rentedMotors: rentedMotors,
      totalMotors: activeMotorsCount,
      todayIncome: todayIncome,
      lowStockDrinks: lowStockDrinks,
    ));
  }

  controller = StreamController<DashboardStats>(
    onListen: () {
      final sub1 = roomsStream.listen((snap) { roomsSnap = snap; tryEmit(); });
      final sub2 = motorsStream.listen((snap) { motorsSnap = snap; tryEmit(); });
      final sub3 = motorSewaStream.listen((snap) { motorSewaSnap = snap; tryEmit(); });
      final sub4 = financeStream1.listen((snap) { financeSnap1 = snap; tryEmit(); });
      final sub6 = drinksStream.listen((snap) { drinksSnap = snap; tryEmit(); });
      final sub7 = reservasiStream.listen((snap) { reservasiSnap = snap; tryEmit(); });

      controller?.onCancel = () {
        sub1.cancel();
        sub2.cancel();
        sub3.cancel();
        sub4.cancel();
        sub6.cancel();
        sub7.cancel();
      };
    },
  );

  return controller.stream;
});
