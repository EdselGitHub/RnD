import 'package:cloud_firestore/cloud_firestore.dart';

import '../entities/motorcycle_entity.dart';
import '../constants/app_constants.dart';

class MotorcycleModel extends MotorcycleEntity {
  const MotorcycleModel({
    required super.id,
    required super.nama,
    required super.platNumber,
    required super.harga,
    required super.status,
  });

  bool get isAvailable => status == AppStrings.motorAvailable || status == 'tersedia';



  factory MotorcycleModel.fromMap(Map<String, dynamic> map, String id) {
    return MotorcycleModel(
      id: id,
      nama: map['nama'] as String? ?? '',
      platNumber: map['plat_number'] as String? ?? '',
      harga: (map['harga'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? AppStrings.motorAvailable,
    );
  }

  factory MotorcycleModel.fromDoc(DocumentSnapshot doc) {
    return MotorcycleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'plat_number': platNumber,
      'harga': harga,
      'status': status,
    };
  }
}

