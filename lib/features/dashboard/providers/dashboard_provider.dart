import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';

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

/// Auto-complete expired motor rentals in Firestore.
/// If a rental is still 'aktif' but tanggalSelesai has passed,
/// mark the rental as 'selesai' and the motor as 'tersedia'.
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
        // Mark rental as completed
        await db.collection('Motor_Sewa').doc(doc.id).update({
          'status': 'selesai',
        });

        // Mark motor as available
        final motorIdRef = data['motor_id'];
        final String motorId = motorIdRef is DocumentReference
            ? motorIdRef.id
            : (motorIdRef as String? ?? '');
        if (motorId.isNotEmpty) {
          await db.collection('Motor').doc(motorId).update({
            'status': 'tersedia',
          });
        }
        debugPrint(
            '[Dashboard] Auto-completed expired rental ${doc.id}, motor $motorId');
      } catch (e) {
        debugPrint('[Dashboard] Error auto-completing rental ${doc.id}: $e');
      }
    }
  }
}

final dashboardStatsProvider = StreamProvider<DashboardStats>((ref) {
  final db = ref.watch(firestoreServiceProvider).db;

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  // We use multiple streams and combine them manually since we don't have rxdart
  final roomsStream = db.collection('Ruangan').snapshots();
  final motorsStream = db.collection('Motor').snapshots();
  final motorSewaStream = db.collection('Motor_Sewa').snapshots();
  final financeStream1 = db
      .collection('Transaksi_Keuangan')
      .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('tanggal', isLessThan: Timestamp.fromDate(endOfDay))
      .snapshots();
  final drinksStream = db.collection('Minuman').where('stok', isLessThan: 2).snapshots();
  final reservasiStream = db.collection('Reservasi').where('status', isEqualTo: 'aktif').snapshots();

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

    // Auto-complete expired rentals in Firestore (fire-and-forget)
    _autoCompleteExpiredRentals(db, motorSewaSnap!);

    final now = DateTime.now();

    final occupiedRooms = roomsSnap!.docs.where((d) {
      final roomData = d.data() as Map<String, dynamic>;
      if (roomData['status'] == 'dihapus' || roomData['status'] == 'maintenance') return false;

      bool isOccupiedNow = reservasiSnap!.docs.any((resDoc) {
        final resData = resDoc.data() as Map<String, dynamic>;
        
        final roomIdRef = resData['room_id'];
        final String resRoomId = roomIdRef is DocumentReference ? roomIdRef.id : (roomIdRef as String? ?? '');

        if (resRoomId != d.id) return false;

        final checkin = (resData['checkin'] as Timestamp?)?.toDate() ?? DateTime.now();
        final checkout = (resData['checkout'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        return now.compareTo(checkin) >= 0 && now.compareTo(checkout) < 0;
      });

      return isOccupiedNow;
    }).length;

    // Calculate rented motors based on actual rental dates, not static status
    // Uses same logic as motorcycle_list_screen: aktif + now within rental period
    final activeMotorsDocs = motorsSnap!.docs
        .where((d) => (d.data() as Map<String, dynamic>)['status'] != 'dihapus')
        .toList();

    int rentedMotors = 0;
    for (final motorDoc in activeMotorsDocs) {
      final motorData = motorDoc.data() as Map<String, dynamic>;
      // Skip maintenance motors — they are neither rented nor available
      if (motorData['status'] == 'maintenance') continue;

      // Check if there's any active rental for this motor where now is within rental period
      final isRentedNow = motorSewaSnap!.docs.any((sewaDoc) {
        final sewaData = sewaDoc.data() as Map<String, dynamic>;
        final sewaStatus = sewaData['status'] as String? ?? '';
        if (sewaStatus != 'aktif') return false;

        final motorIdRef = sewaData['motor_id'];
        final String sewaMotorId = motorIdRef is DocumentReference
            ? motorIdRef.id
            : (motorIdRef as String? ?? '');
        if (sewaMotorId != motorDoc.id) return false;

        final tanggal =
            (sewaData['tanggal'] as Timestamp?)?.toDate();
        final tanggalSelesai =
            (sewaData['tanggal_selesai'] as Timestamp?)?.toDate();
        
        if (tanggal == null) return false;

        if (tanggalSelesai == null) {
          return now.compareTo(tanggal) >= 0;
        }

        return now.compareTo(tanggal) >= 0 && now.compareTo(tanggalSelesai) < 0;
      });

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

    final lowStockDrinks = drinksSnap!.docs
        .map((d) => (d.data() as Map<String, dynamic>)['nama'] as String)
        .toList();

    final activeRoomsCount = roomsSnap!.docs
        .where((d) => (d.data() as Map<String, dynamic>)['status'] != 'dihapus')
        .length;

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
