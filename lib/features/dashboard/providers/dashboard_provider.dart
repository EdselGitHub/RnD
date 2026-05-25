import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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

final dashboardStatsProvider = StreamProvider<DashboardStats>((ref) {
  final db = ref.watch(firestoreServiceProvider).db;

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  // We use multiple streams and combine them manually since we don't have rxdart
  final roomsStream = db.collection('Ruangan').snapshots();
  final motorsStream = db.collection('Motor').snapshots();
  final financeStream1 = db
      .collection('Transkasi_Keuangan')
      .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('tanggal', isLessThan: Timestamp.fromDate(endOfDay))
      .snapshots();
  final financeStream2 = db
      .collection('Transaksi_Keuangan')
      .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('tanggal', isLessThan: Timestamp.fromDate(endOfDay))
      .snapshots();
  final drinksStream = db.collection('Minuman').where('stok', isLessThan: 2).snapshots();
  final reservasiStream = db.collection('Reservasi').where('status', isEqualTo: 'aktif').snapshots();

  StreamController<DashboardStats>? controller;
  
  QuerySnapshot? roomsSnap;
  QuerySnapshot? motorsSnap;
  QuerySnapshot? financeSnap1;
  QuerySnapshot? financeSnap2;
  QuerySnapshot? drinksSnap;
  QuerySnapshot? reservasiSnap;

  void tryEmit() {
    if (roomsSnap == null || motorsSnap == null || financeSnap1 == null || financeSnap2 == null || drinksSnap == null || reservasiSnap == null) {
      return;
    }

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

    final rentedMotors = motorsSnap!.docs
        .where((d) => (d.data() as Map<String, dynamic>)['status'] == 'disewa')
        .length;

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
    for (final doc in financeSnap2!.docs) {
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

    final activeMotorsCount = motorsSnap!.docs
        .where((d) => (d.data() as Map<String, dynamic>)['status'] != 'dihapus')
        .length;

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
      final sub3 = financeStream1.listen((snap) { financeSnap1 = snap; tryEmit(); });
      final sub4 = financeStream2.listen((snap) { financeSnap2 = snap; tryEmit(); });
      final sub5 = drinksStream.listen((snap) { drinksSnap = snap; tryEmit(); });
      final sub6 = reservasiStream.listen((snap) { reservasiSnap = snap; tryEmit(); });

      controller?.onCancel = () {
        sub1.cancel();
        sub2.cancel();
        sub3.cancel();
        sub4.cancel();
        sub5.cancel();
        sub6.cancel();
      };
    },
  );

  return controller.stream;
});
