import 'package:cloud_firestore/cloud_firestore.dart';

import '../entities/laundry_entity.dart';

class LaundryModel extends LaundryEntity {
  final DateTime createdAt;

  const LaundryModel({
    required super.id,
    required super.tamuId,
    required super.beratKG,
    required super.harga,
    required super.hargaPerKG,
    required super.jenis,
    required super.status,
    required super.roomNumber,
    required this.createdAt,
  });

  factory LaundryModel.fromMap(Map<String, dynamic> map, String id) {
    // Get tamu_id — could be a DocumentReference or a plain string
    final rawTamuId = map['tamu_id'] ?? map['guest_id'] ?? map['user_id'];
    final tamuId = rawTamuId is DocumentReference
        ? rawTamuId.id
        : rawTamuId as String? ?? '';

    // Determine room number — try multiple field names from different apps
    String roomNumber = '';
    for (final key in ['no_kamar', 'room_number', 'room', 'kamar', 'nomor_kamar']) {
      final v = map[key];
      if (v != null && v.toString().isNotEmpty) {
        roomNumber = v.toString();
        break;
      }
    }
    // Fallback: parse from tamuId with format "[201]"
    if (roomNumber.isEmpty && tamuId.isNotEmpty) {
      final match = RegExp(r'\[(\d+)\]').firstMatch(tamuId);
      if (match != null) roomNumber = 'Kamar ${match.group(1)}';
    }

    // createdAt: coba nama field yang diketahui terlebih dahulu
    DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    for (final key in ['createdAt', 'created_at', 'tanggal', 'pembuatan', 'waktu', 'timestamp']) {
      if (map[key] is Timestamp) {
        createdAt = (map[key] as Timestamp).toDate();
        break;
      }
    }
    // Fallback terakhir: scan SEMUA field — tangkap timestamp dari app manapun
    if (createdAt.millisecondsSinceEpoch == 0) {
      for (final entry in map.entries) {
        // Skip field jadwal/schedule yang biasanya di masa depan
        if (['jadwal', 'schedule', 'scheduled_at', 'check_in', 'checkout'].contains(entry.key)) continue;
        if (entry.value is Timestamp) {
          final dt = (entry.value as Timestamp).toDate();
          // Ambil timestamp yang paling awal (waktu pembuatan, bukan jadwal masa depan)
          if (createdAt.millisecondsSinceEpoch == 0 || dt.isBefore(createdAt)) {
            createdAt = dt;
          }
        }
      }
    }

    // beratKG: try multiple field names
    double beratKG = 0.0;
    for (final key in ['beratKG', 'berat', 'weight', 'kg', 'berat_kg']) {
      final v = map[key];
      if (v != null) {
        beratKG = (v as num).toDouble();
        break;
      }
    }

    // hargaPerKG: try multiple field names
    double hargaPerKG = 15000.0;
    for (final key in ['hargaPerKG', 'harga_per_kg', 'price_per_kg', 'tarif']) {
      final v = map[key];
      if (v != null) {
        hargaPerKG = (v as num).toDouble();
        break;
      }
    }

    // harga total
    double harga = 0.0;
    final rawHarga = map['harga'] ?? map['total'] ?? map['total_harga'] ?? map['price'];
    if (rawHarga != null) harga = (rawHarga as num).toDouble();
    if (harga == 0.0 && beratKG > 0) harga = beratKG * hargaPerKG;

    // jenis layanan
    String jenis = 'regular';
    for (final key in ['jenis', 'type', 'service', 'layanan', 'jenis_layanan']) {
      final v = map[key];
      if (v != null && v.toString().isNotEmpty) {
        jenis = v.toString();
        break;
      }
    }

    // status
    String status = 'menunggu';
    for (final key in ['status', 'state', 'kondisi']) {
      final v = map[key];
      if (v != null && v.toString().isNotEmpty) {
        status = v.toString();
        break;
      }
    }

    return LaundryModel(
      id: id,
      tamuId: tamuId,
      beratKG: beratKG,
      harga: harga,
      hargaPerKG: hargaPerKG,
      jenis: jenis,
      status: status,
      roomNumber: roomNumber,
      createdAt: createdAt,
    );
  }

  factory LaundryModel.fromDoc(DocumentSnapshot doc) {
    return LaundryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }




}
