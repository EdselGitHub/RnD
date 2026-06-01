import 'package:cloud_firestore/cloud_firestore.dart';

import '../entities/room_entity.dart';

class RoomModel extends RoomEntity {
  const RoomModel({
    required super.id,
    required super.nama,
    required super.harga,
    super.hargaMingguan = 0.0,
    super.hargaBulanan = 0.0,
    required super.status,
    super.tipe = '',
  });

  bool get isAvailable => status == 'tersedia';



  factory RoomModel.fromMap(Map<String, dynamic> map, String id) {
    return RoomModel(
      id: id,
      nama: map['nama'] as String? ?? '',
      harga: (map['harga'] as num?)?.toDouble() ?? 0.0,
      hargaMingguan: (map['harga_mingguan'] as num?)?.toDouble() ?? 0.0,
      hargaBulanan: (map['harga_bulanan'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'tersedia',
      tipe: map['tipe'] as String? ?? '',
    );
  }

  factory RoomModel.fromDoc(DocumentSnapshot doc) {
    return RoomModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'harga': harga,
      'harga_mingguan': hargaMingguan,
      'harga_bulanan': hargaBulanan,
      'status': status,
      'tipe': tipe,
    };
  }
}

