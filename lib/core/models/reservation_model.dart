import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String id;
  final String roomId; // reference to Ruangan
  final String tamuId; // reference to Tamu
  final DateTime checkin;
  final DateTime checkout;
  final double total;
  final String status; // 'aktif' | 'selesai' | 'dibatalkan'

  // Cached display fields (not stored in Firestore)
  final String _roomName;
  final String _guestName;

  const ReservationModel({
    required this.id,
    required this.roomId,
    required this.tamuId,
    required this.checkin,
    required this.checkout,
    required this.total,
    required this.status,
    String roomName = '',
    String guestName = '',
  })  : _roomName = roomName,
        _guestName = guestName;

  int get nights => checkout.difference(checkin).inDays;

  // Getter aliases used in UI
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

