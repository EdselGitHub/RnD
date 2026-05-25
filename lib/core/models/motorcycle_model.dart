import 'package:cloud_firestore/cloud_firestore.dart';

class MotorcycleModel {
  final String id;
  final String nama;
  final double harga;
  final String status; // 'tersedia' | 'disewa' | 'maintenance'

  const MotorcycleModel({
    required this.id,
    required this.nama,
    required this.harga,
    required this.status,
  });

  bool get isAvailable => status == 'tersedia';



  factory MotorcycleModel.fromMap(Map<String, dynamic> map, String id) {
    return MotorcycleModel(
      id: id,
      nama: map['nama'] as String? ?? '',
      harga: (map['harga'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'tersedia',
    );
  }

  factory MotorcycleModel.fromDoc(DocumentSnapshot doc) {
    return MotorcycleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'harga': harga,
      'status': status,
    };
  }
}

