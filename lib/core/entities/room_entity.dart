class RoomEntity {
  final String id;
  final String nama;
  final double harga;
  final double hargaMingguan;
  final double hargaBulanan;
  final String status; // 'tersedia' | 'tidak tersedia'
  final String tipe;

  const RoomEntity({
    required this.id,
    required this.nama,
    required this.harga,
    this.hargaMingguan = 0.0,
    this.hargaBulanan = 0.0,
    required this.status,
    this.tipe = '',
  });
}
