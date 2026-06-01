class RoomServiceEntity {
  final String id;
  final String roomId; // reference to Ruangan
  final String deskripsi;
  final DateTime jadwal;
  final DateTime pembuatan; // tanggal request cleaning room dibuat
  final String status; // 'menunggu' | 'proses' | 'selesai'

  const RoomServiceEntity({
    required this.id,
    required this.roomId,
    required this.deskripsi,
    required this.jadwal,
    required this.pembuatan,
    required this.status,
  });
}
