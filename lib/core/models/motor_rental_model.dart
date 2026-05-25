import 'package:cloud_firestore/cloud_firestore.dart';

class MotorRentalModel {
  final String id;
  final String motorId; // reference to Motor
  final String tamuId; // reference to Tamu
  final double hargaPerhari; // 150000
  final String status; // 'aktif' | 'selesai' | 'dibatalkan'
  final DateTime tanggal;
  final DateTime tanggalSelesai;
  final DateTime pembuatan; // tanggal order dibuat
  final double total;
  final String unit;

  const MotorRentalModel({
    required this.id,
    required this.motorId,
    required this.tamuId,
    required this.hargaPerhari,
    required this.status,
    required this.tanggal,
    required this.tanggalSelesai,
    required this.pembuatan,
    required this.total,
    required this.unit,
  });

  factory MotorRentalModel.fromMap(Map<String, dynamic> map, String id) {
    return MotorRentalModel(
      id: id,
      motorId: map['motor_id'] is DocumentReference
          ? (map['motor_id'] as DocumentReference).id
          : map['motor_id'] as String? ?? '',
      tamuId: map['tamu_id'] is DocumentReference
          ? (map['tamu_id'] as DocumentReference).id
          : map['tamu_id'] as String? ?? '',
      hargaPerhari: (map['harga_perhari'] as num?)?.toDouble() ?? 150000.0,
      status: map['status'] as String? ?? 'aktif',
      tanggal: (map['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tanggalSelesai: (map['tanggal_selesai'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pembuatan: (map['pembuatan'] as Timestamp?)?.toDate() ?? DateTime.now(),
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? '',
    );
  }

  factory MotorRentalModel.fromDoc(DocumentSnapshot doc) {
    return MotorRentalModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }




}
