class MotorcycleEntity {
  final String id;
  final String nama;
  final double harga;
  final String status; // 'tersedia' | 'disewa' | 'maintenance'

  const MotorcycleEntity({
    required this.id,
    required this.nama,
    required this.harga,
    required this.status,
  });
}
