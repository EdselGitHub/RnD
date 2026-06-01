import 'package:cloud_firestore/cloud_firestore.dart';

import '../entities/drink_transaction_entity.dart';

class DrinkTransactionModel extends DrinkTransactionEntity {
  const DrinkTransactionModel({
    required super.id,
    required super.minumanId,
    required super.pembuatan,
    required super.qty,
    required super.tanggal,
    required super.total,
  });
  factory DrinkTransactionModel.fromMap(
      Map<String, dynamic> map, String id) {
    return DrinkTransactionModel(
      id: id,
      minumanId: map['minuman_id'] is DocumentReference
          ? (map['minuman_id'] as DocumentReference).id
          : map['minuman_id'] as String? ?? '',
      pembuatan: (map['pembuatan'] as Timestamp?)?.toDate() ?? DateTime.now(),
      qty: (map['qty'] as num?)?.toInt() ?? 0,
      tanggal: (map['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory DrinkTransactionModel.fromDoc(DocumentSnapshot doc) {
    return DrinkTransactionModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }


}
