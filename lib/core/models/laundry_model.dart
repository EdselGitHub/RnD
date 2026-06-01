import 'package:cloud_firestore/cloud_firestore.dart';

import '../entities/laundry_entity.dart';

class LaundryModel extends LaundryEntity {
  const LaundryModel({
    required super.id,
    required super.tamuId,
    required super.beratKG,
    required super.harga,
    required super.hargaPerKG,
    required super.jenis,
    required super.status,
    required super.roomNumber,
  });

  factory LaundryModel.fromMap(Map<String, dynamic> map, String id) {
    // Get tamu_id — could be a DocumentReference or a plain string
    final rawTamuId = map['tamu_id'];
    final tamuId = rawTamuId is DocumentReference
        ? rawTamuId.id
        : rawTamuId as String? ?? '';

    // Determine room number:
    // 1. Prefer explicit 'no_kamar' field (from this app)
    // 2. Fallback: parse from tamu_id with format "Laundry [201] - Name" (from guest app)
    String roomNumber = map['no_kamar'] as String? ?? '';
    if (roomNumber.isEmpty && tamuId is String) {
      final match = RegExp(r'\[(\d+)\]').firstMatch(tamuId);
      if (match != null) {
        roomNumber = 'Kamar ${match.group(1)}';
      }
    }

    return LaundryModel(
      id: id,
      tamuId: tamuId,
      beratKG: (map['beratKG'] as num?)?.toDouble() ?? 0.0,
      harga: (map['harga'] as num?)?.toDouble() ?? 0.0,
      hargaPerKG: (map['hargaPerKG'] as num?)?.toDouble() ?? 15000.0,
      jenis: map['jenis'] as String? ?? 'regular',
      status: map['status'] as String? ?? 'menunggu',
      roomNumber: roomNumber,
    );
  }

  factory LaundryModel.fromDoc(DocumentSnapshot doc) {
    return LaundryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }




}
