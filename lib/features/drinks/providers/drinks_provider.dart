import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/drink_model.dart';
import '../../../core/models/drink_transaction_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/constants/firestore_constants.dart';

final drinksStreamProvider = StreamProvider<List<DrinkModel>>((ref) {
  final db = ref.watch(firestoreServiceProvider).db;
  return db
      .collection(FirestoreCollections.minuman)
      .orderBy('nama')
      .snapshots()
      .map((snap) => snap.docs.map((d) => DrinkModel.fromDoc(d)).toList());
});

final drinkTransactionsStreamProvider =
    StreamProvider<List<DrinkTransactionModel>>((ref) {
  final db = ref.watch(firestoreServiceProvider).db;
  return db
      .collection(FirestoreCollections.pembelianMinuman)
      .orderBy('pembuatan', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => DrinkTransactionModel.fromDoc(d)).toList());
});

class DrinksNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addDrink({
    required String name,
    required double price,
    required int stock,
  }) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection(FirestoreCollections.minuman).add({
      'nama': name,
      'harga': price,
      'stok': stock,
    });
  }

  Future<void> sellDrink({
    required DrinkModel drink,
    required int quantity,
    required String createdBy,
  }) async {
    final db = ref.read(firestoreServiceProvider).db;
    final total = drink.harga * quantity;
    final newStock = drink.stok - quantity;

    // Update stock in Minuman
    await db.collection(FirestoreCollections.minuman).doc(drink.id).update({'stok': newStock});

    // Record transaction in Pembelian_Minuman
    final now = DateTime.now();
    await db.collection(FirestoreCollections.pembelianMinuman).add({
      'minuman_id': db.collection(FirestoreCollections.minuman).doc(drink.id),
      'pembuatan': Timestamp.fromDate(now),
      'qty': quantity,
      'tanggal': Timestamp.fromDate(now),
      'total': total,
    });

    // Finance record in Transaksi_Keuangan
    await db.collection(FirestoreCollections.transaksiKeuangan).add({
      'kategori': 'minuman',
      'deskripsi': 'Minuman ${drink.nama} ($quantity x)',
      'jumlah': total,
      'tanggal': Timestamp.fromDate(now),
      'tipe': 'income',
    });
  }

  Future<void> updateStock(String drinkId, int newStock) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection(FirestoreCollections.minuman).doc(drinkId).update({'stok': newStock});
  }

  Future<void> deleteDrink(String drinkId) async {
    final db = ref.read(firestoreServiceProvider).db;
    await db.collection(FirestoreCollections.minuman).doc(drinkId).delete();
  }
}

final drinksNotifierProvider =
    AsyncNotifierProvider<DrinksNotifier, void>(() => DrinksNotifier());
