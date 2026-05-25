import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String nama;
  final double harga;
  final double hargaMingguan;
  final double hargaBulanan;
  final String status; // 'tersedia' | 'tidak tersedia' | 'maintenance'
  final String tipe;

  const RoomModel({
    required this.id,
    required this.nama,
    required this.harga,
    this.hargaMingguan = 0.0,
    this.hargaBulanan = 0.0,
    required this.status,
    this.tipe = '',
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

