import 'package:cloud_firestore/cloud_firestore.dart';

import '../entities/reservation_entity.dart';

class ReservationModel extends ReservationEntity {
  //tidak dimasukkan ke firestore
  final String _roomName;
  final String _guestName;

  const ReservationModel({
    required super.id,
    required super.roomId,
    required super.tamuId,
    required super.checkin,
    required super.checkout,
    required super.total,
    required super.status,
    String roomName = '',
    String guestName = '',
  })  : _roomName = roomName,
        _guestName = guestName;

  int get nights => checkout.difference(checkin).inDays;

  // dipakai di ui
  String get roomNumber => _roomName;
  String get guestName => _guestName;

  factory ReservationModel.fromMap(Map<String, dynamic> map, String id) {
    return ReservationModel(
      id: id,
      roomId: map['room_id'] is DocumentReference
          ? (map['room_id'] as DocumentReference).id
          : map['room_id'] as String? ?? '',
      tamuId: map['tamu_id'] is DocumentReference
          ? (map['tamu_id'] as DocumentReference).id
          : map['tamu_id'] as String? ?? '',
      checkin: (map['checkin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      checkout: (map['checkout'] as Timestamp?)?.toDate() ?? DateTime.now(),
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'aktif',
    );
  }

  factory ReservationModel.fromDoc(DocumentSnapshot doc) {
    return ReservationModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }
}
