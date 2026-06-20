import 'package:cloud_firestore/cloud_firestore.dart';

import '../entities/finance_record_entity.dart';

class FinanceRecordModel extends FinanceRecordEntity {
  const FinanceRecordModel({
    required super.id,
    required super.jumlah,
    required super.kategori,
    super.deskripsi,
    required super.tanggal,
    required super.tipe,
    super.kartuIdentitas,
  });

  bool get isIncome => tipe == 'income';

  //getter pencocokan untuk UI
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
