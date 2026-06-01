class LaundryEntity {
  final String id;
  final String tamuId; // reference to Tamu
  final double beratKG;
  final double harga;
  final double hargaPerKG; // default 15000
  final String jenis; // 'regular'
  final String status; // 'menunggu' | 'proses' | 'selesai'
  final String roomNumber;

  const LaundryEntity({
    required this.id,
    required this.tamuId,
    required this.beratKG,
    required this.harga,
    required this.hargaPerKG,
    required this.jenis,
    required this.status,
    required this.roomNumber,
  });
}
