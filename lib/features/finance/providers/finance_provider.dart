import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/finance_record_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/constants/firestore_constants.dart';

enum FinancePeriod { daily, monthly }

final financePeriodProvider =
    StateProvider<FinancePeriod>((ref) => FinancePeriod.daily);

final financeCategoryFilterProvider = StateProvider<String?>((ref) => null);

final financeSelectedDateProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

final financeRecordsProvider = StreamProvider<List<FinanceRecordModel>>((ref) {
  final db = ref.watch(firestoreServiceProvider).db;
  final period = ref.watch(financePeriodProvider);
  final category = ref.watch(financeCategoryFilterProvider);
  final selectedDate = ref.watch(financeSelectedDateProvider);

  final now = DateTime.now();
  DateTime start;
  DateTime end;

  if (period == FinancePeriod.daily) {
    start = DateTime(now.year, now.month, now.day);
    end = start.add(const Duration(days: 1));
  } else {
    start = DateTime(selectedDate.year, selectedDate.month, 1);
    end = DateTime(selectedDate.year, selectedDate.month + 1, 1);
  }

  final streamController = StreamController<List<FinanceRecordModel>>();

  QuerySnapshot? snap1;

  void tryEmit() {
    if (snap1 == null) return;

    final allDocs = <DocumentSnapshot>[...snap1!.docs];
    final List<FinanceRecordModel> records = [];
    for (final d in allDocs) {
      final r = FinanceRecordModel.fromDoc(d);
      
      final inRange = r.tanggal.isAfter(start.subtract(const Duration(seconds: 1))) &&
          r.tanggal.isBefore(end);
      
      final bool matchCategory;
      if (category == null) {
        matchCategory = true;
      } else if (category == 'pengeluaran') {
        matchCategory = !r.isIncome;
      } else if (category == 'kamar') {
        matchCategory = r.kategori == 'kamar' || r.kategori == 'penjualan kamar';
      } else {
        matchCategory = r.kategori == category;
      }

      if (inRange && matchCategory) {
        records.add(r);
      }
    }
    records.sort((a, b) => b.tanggal.compareTo(a.tanggal));

    streamController.add(records);
  }

  streamController.onListen = () {
    final sub1 = db.collection(FirestoreCollections.transaksiKeuangan).snapshots().listen((snap) {
      snap1 = snap;
      tryEmit();
    });

    streamController.onCancel = () {
      sub1.cancel();
    };
  };

  return streamController.stream;
});

final financeByCategory = Provider<AsyncValue<Map<String, double>>>((ref) {
  final recordsAsync = ref.watch(financeRecordsProvider);
  
  return recordsAsync.whenData((records) {
    final Map<String, double> result = {};
    for (final r in records) {
      if (r.isIncome) {
        final key = r.kategori == 'penjualan kamar' ? 'kamar' : r.kategori;
        result[key] = (result[key] ?? 0) + r.jumlah;
      }
    }
    return result;
  });
});

class FinanceNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addExpense(String description, double amount, DateTime expenseDate) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection(FirestoreCollections.transaksiKeuangan).add({
      'kategori': description,
      'jumlah': amount,
      // 'tanggal': Timestamp.fromDate(DateTime.now()),
      'tanggal': Timestamp.fromDate(expenseDate),
      'tipe': 'expense',
    });
  }

  Future<void> deleteTransaction(FinanceRecordModel record) async {
    final db = ref.read(firestoreServiceProvider).db;

    // Jika transaksi ini adalah penyewaan kamar
    if (record.category == 'kamar' || record.category == 'penjualan kamar') {
      try {
        final resDocs = await db
            .collection(FirestoreCollections.reservasi)
            .where('total', isEqualTo: record.amount)
            .get();

        for (var doc in resDocs.docs) {
          final data = doc.data();
          final checkinTime = (data['checkin'] as Timestamp?)?.toDate();

          //cari reservasi yang tanggal checkin-nya sama/berdekatan dengan transaksi
          if (checkinTime != null &&
              checkinTime.difference(record.date).abs().inMinutes < 120) {
            
            //1. batalkan status reservasi
            await db
                .collection(FirestoreCollections.reservasi)
                .doc(doc.id)
                .update({'status': 'dibatalkan'});

            //2.ubah status ruangan menjadi tersedia kembali
            final roomIdRef = data['room_id'];
            if (roomIdRef is DocumentReference) {
              await roomIdRef.update({'status': 'tersedia'});
            } else if (roomIdRef is String && roomIdRef.isNotEmpty) {
              await db
                  .collection(FirestoreCollections.ruangan)
                  .doc(roomIdRef)
                  .update({'status': 'tersedia'});
            }
            break;
          }
        }
      } catch (e) {
        //abaikan atau log error agar tidak menghentikan proses hapus transaksi utama
      }
    }

    //hapus record transaksi keuangan
    await db.collection(FirestoreCollections.transaksiKeuangan).doc(record.id).delete();
  }
}

final financeNotifierProvider =
    AsyncNotifierProvider<FinanceNotifier, void>(() => FinanceNotifier());
