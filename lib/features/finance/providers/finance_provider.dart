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
    
    final records = allDocs
        .map((d) => FinanceRecordModel.fromDoc(d))
        .where((r) {
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
          
          return inRange && matchCategory;
        })
        .toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

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

  Future<void> addExpense(String description, double amount) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection(FirestoreCollections.transaksiKeuangan).add({
      'kategori': description,
      'jumlah': amount,
      'tanggal': Timestamp.fromDate(DateTime.now()),
      'tipe': 'expense',
    });
  }
}

final financeNotifierProvider =
    AsyncNotifierProvider<FinanceNotifier, void>(() => FinanceNotifier());
