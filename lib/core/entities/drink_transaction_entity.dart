class DrinkTransactionEntity {
  final String id;
  final String minumanId; // reference to Minuman
  final DateTime pembuatan; // tanggal order dibuat
  final int qty;
  final DateTime tanggal;
  final double total;

  const DrinkTransactionEntity({
    required this.id,
    required this.minumanId,
    required this.pembuatan,
    required this.qty,
    required this.tanggal,
    required this.total,
  });
}
