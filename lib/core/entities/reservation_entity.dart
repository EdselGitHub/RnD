class ReservationEntity {
  final String id;
  final String roomId; // reference to Ruangan
  final String tamuId; // reference to Tamu
  final DateTime checkin;
  final DateTime checkout;
  final double total;
  final String status; // 'aktif' | 'selesai' | 'dibatalkan'

  const ReservationEntity({
    required this.id,
    required this.roomId,
    required this.tamuId,
    required this.checkin,
    required this.checkout,
    required this.total,
    required this.status,
  });
}
