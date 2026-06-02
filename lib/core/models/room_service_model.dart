import 'package:cloud_firestore/cloud_firestore.dart';

import '../entities/room_service_entity.dart';

class RoomServiceModel extends RoomServiceEntity {
  // Cached display field (not stored in Firestore)
  final String _roomNumber;

  const RoomServiceModel({
    required super.id,
    required super.roomId,
    required super.deskripsi,
    required super.jadwal,
    required super.pembuatan,
    required super.status,
    String roomNumber = '',
  }) : _roomNumber = roomNumber;

  // Getter aliases used in UI
  String get roomNumber => _roomNumber;
  DateTime get scheduledAt => jadwal;
  DateTime get createdAt => pembuatan;

  factory RoomServiceModel.fromMap(Map<String, dynamic> map, String id) {
    // Coba berbagai nama field untuk waktu pembuatan (kompatibel dengan user app)
    DateTime pembuatan = DateTime.fromMillisecondsSinceEpoch(0);
    for (final key in ['pembuatan', 'createdAt', 'created_at', 'tanggal']) {
      if (map[key] is Timestamp) {
        pembuatan = (map[key] as Timestamp).toDate();
        break;
      }
    }

    // Coba berbagai nama field untuk nomor kamar (kompatibel dengan user app)
    String roomNumber = map['room_number'] as String? ?? '';
    if (roomNumber.isEmpty) {
      roomNumber = map['no_kamar'] as String? ?? map['roomNumber'] as String? ?? '';
    }

    return RoomServiceModel(
      id: id,
      roomId: map['room_id'] is DocumentReference
          ? (map['room_id'] as DocumentReference).id
          : map['room_id'] as String? ?? '',
      roomNumber: roomNumber,
      deskripsi: map['deskripsi'] as String? ?? map['notes'] as String? ?? '',
      jadwal: (map['jadwal'] as Timestamp?)?.toDate() ??
          (map['scheduled_at'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      pembuatan: pembuatan,
      status: map['status'] as String? ?? 'menunggu',
    );
  }

  factory RoomServiceModel.fromDoc(DocumentSnapshot doc) {
    return RoomServiceModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }




}
