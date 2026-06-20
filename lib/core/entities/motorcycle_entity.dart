class MotorcycleEntity {
  final String id;
  final String nama;
  final String platNumber;
  final double harga;
  final String status; // 'tersedia' | 'disewa'

  const MotorcycleEntity({
    required this.id,
    required this.nama,
    required this.platNumber,
    required this.harga,
    required this.status,
  });
}
