class MotorRentalEntity {
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

  const MotorRentalEntity({
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
}
