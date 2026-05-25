import 'package:cloud_firestore/cloud_firestore.dart';

class LaundryModel {
  final String id;
  final String tamuId; // reference to Tamu
  final double beratKG;
  final double harga;
  final double hargaPerKG; // default 15000
  final String jenis; // 'regular'
  final String status; // 'menunggu' | 'proses' | 'selesai'
  final String roomNumber;

  const LaundryModel({
    required this.id,
    required this.tamuId,
    required this.beratKG,
    required this.harga,
    required this.hargaPerKG,
    required this.jenis,
    required this.status,
    required this.roomNumber,
  });

  factory LaundryModel.fromMap(Map<String, dynamic> map, String id) {
    return LaundryModel(
      id: id,
      tamuId: map['tamu_id'] is DocumentReference
          ? (map['tamu_id'] as DocumentReference).id
          : map['tamu_id'] as String? ?? '',
      beratKG: (map['beratKG'] as num?)?.toDouble() ?? 0.0,
      harga: (map['harga'] as num?)?.toDouble() ?? 0.0,
      hargaPerKG: (map['hargaPerKG'] as num?)?.toDouble() ?? 15000.0,
      jenis: map['jenis'] as String? ?? 'regular',
      status: map['status'] as String? ?? 'menunggu',
      roomNumber: map['no_kamar'] as String? ?? '',
    );
  }

  factory LaundryModel.fromDoc(DocumentSnapshot doc) {
    return LaundryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }




}
