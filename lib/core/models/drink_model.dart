import 'package:cloud_firestore/cloud_firestore.dart';

import '../entities/drink_entity.dart';

class DrinkModel extends DrinkEntity {
  const DrinkModel({
    required super.id,
    required super.nama,
    required super.harga,
    required super.stok,
  });

  bool get isLowStock => stok < 2;

  factory DrinkModel.fromMap(Map<String, dynamic> map, String id) {
    return DrinkModel(
      id: id,
      nama: map['nama'] as String? ?? '',
      harga: (map['harga'] as num?)?.toDouble() ?? 0.0,
      stok: (map['stok'] as num?)?.toInt() ?? 0,
    );
  }

  factory DrinkModel.fromDoc(DocumentSnapshot doc) {
    return DrinkModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'harga': harga,
      'stok': stok,
    };
  }
}

