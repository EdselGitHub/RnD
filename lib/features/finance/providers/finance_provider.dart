import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/finance_record_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';

enum FinancePeriod { daily, monthly }

final financePeriodProvider =
    StateProvider<FinancePeriod>((ref) => FinancePeriod.daily);

final financeCategoryFilterProvider = StateProvider<String?>((ref) => null);

final financeRecordsProvider = StreamProvider<List<FinanceRecordModel>>((ref) {
  final db = ref.watch(firestoreServiceProvider).db;
  final period = ref.watch(financePeriodProvider);
  final category = ref.watch(financeCategoryFilterProvider);

  final now = DateTime.now();
  DateTime start;
  DateTime end;

  if (period == FinancePeriod.daily) {
    start = DateTime(now.year, now.month, now.day);
    end = start.add(const Duration(days: 1));
  } else {
    start = DateTime(now.year, now.month, 1);
    end = DateTime(now.year, now.month + 1, 1);
  }

  final streamController = StreamController<List<FinanceRecordModel>>();

  QuerySnapshot? snap1;
  QuerySnapshot? snap2;

  void tryEmit() {
    if (snap1 == null || snap2 == null) return;

    final allDocs = <DocumentSnapshot>[...snap1!.docs, ...snap2!.docs];
    
    final records = allDocs
        .map((d) => FinanceRecordModel.fromDoc(d))
        .where((r) {
          final inRange = r.tanggal.isAfter(start.subtract(const Duration(seconds: 1))) &&
              r.tanggal.isBefore(end);
          final matchCategory = category == null || 
              (category == 'pengeluaran' ? !r.isIncome : r.kategori == category);
          return inRange && matchCategory;
        })
        .toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

    streamController.add(records);
  }

  streamController.onListen = () {
    final sub1 = db.collection('Transkasi_Keuangan').snapshots().listen((snap) {
      snap1 = snap;
      tryEmit();
    });
    final sub2 = db.collection('Transaksi_Keuangan').snapshots().listen((snap) {
      snap2 = snap;
      tryEmit();
    });

    streamController.onCancel = () {
      sub1.cancel();
      sub2.cancel();
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
        result[r.kategori] = (result[r.kategori] ?? 0) + r.jumlah;
      }
    }
    return result;
  });
});

class FinanceNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addExpense(String description, double amount) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection('Transaksi_Keuangan').add({
      'kategori': description,
      'jumlah': amount,
      'tanggal': Timestamp.fromDate(DateTime.now()),
      'tipe': 'expense',
    });
  }
}

final financeNotifierProvider =
    AsyncNotifierProvider<FinanceNotifier, void>(() => FinanceNotifier());
