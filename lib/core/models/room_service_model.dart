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
    return RoomServiceModel(
      id: id,
      roomId: map['room_id'] is DocumentReference
          ? (map['room_id'] as DocumentReference).id
          : map['room_id'] as String? ?? '',
      roomNumber: map['room_number'] as String? ?? '',
      deskripsi: map['deskripsi'] as String? ?? '',
      jadwal: (map['jadwal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pembuatan: (map['pembuatan'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] as String? ?? 'menunggu',
    );
  }

  factory RoomServiceModel.fromDoc(DocumentSnapshot doc) {
    return RoomServiceModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }




}
