class FinanceRecordEntity {
  final String id;
  final double jumlah;
  final String kategori; // 'penjualan kamar' | 'laundry' | 'motor' | 'minuman'
  final String? deskripsi;
  final DateTime tanggal;
  final String tipe; // 'income' | 'expense'
  final String? kartuIdentitas; // Field baru untuk path KTP

  const FinanceRecordEntity({
    required this.id,
    required this.jumlah,
    required this.kategori,
    this.deskripsi,
    required this.tanggal,
    required this.tipe,
    this.kartuIdentitas,
  });
}
