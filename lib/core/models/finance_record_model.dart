import 'package:cloud_firestore/cloud_firestore.dart';

class FinanceRecordModel {
  final String id;
  final double jumlah;
  final String kategori; // 'penjualan kamar' | 'laundry' | 'motor' | 'minuman'
  final String? deskripsi;
  final DateTime tanggal;
  final String tipe; // 'income' | 'expense'
  final String? kartuIdentitas; // Field baru untuk path KTP

  const FinanceRecordModel({
    required this.id,
    required this.jumlah,
    required this.kategori,
    this.deskripsi,
    required this.tanggal,
    required this.tipe,
    this.kartuIdentitas,
  });

  bool get isIncome => tipe == 'income';

  // Getter aliases for backward compatibility in UI
  String get category => kategori;
  double get amount => jumlah;
  DateTime get date => tanggal;
  String get type => tipe;
  String get description => deskripsi ?? kategori;


  factory FinanceRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return FinanceRecordModel(
      id: id,
      jumlah: (map['jumlah'] as num?)?.toDouble() ?? 0.0,
      kategori: map['kategori'] as String? ?? '',
      deskripsi: map['deskripsi'] as String?,
      tanggal: (map['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tipe: map['tipe'] as String? ?? 'income',
      kartuIdentitas: map['kartu_identitas'] as String? ?? map['kartuIdentitas'] as String? ?? map['ktp'] as String?,
    );
  }

  factory FinanceRecordModel.fromDoc(DocumentSnapshot doc) {
    return FinanceRecordModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }


}
