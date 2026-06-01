import 'package:cloud_firestore/cloud_firestore.dart';

import '../entities/motor_rental_entity.dart';

class MotorRentalModel extends MotorRentalEntity {
  const MotorRentalModel({
    required super.id,
    required super.motorId,
    required super.tamuId,
    required super.hargaPerhari,
    required super.status,
    required super.tanggal,
    required super.tanggalSelesai,
    required super.pembuatan,
    required super.total,
    required super.unit,
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
      tanggalSelesai: (map['tanggal_selesai'] as Timestamp?)?.toDate() ?? DateTime(2099),
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
