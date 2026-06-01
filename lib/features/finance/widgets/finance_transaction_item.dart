import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/finance_record_model.dart';
import '../constants/finance_constants.dart';
import '../services/finance_resolver_service.dart';

class FinanceTransactionItem extends StatelessWidget {
  final FinanceRecordModel record;
  final NumberFormat currencyFormatter;
  final DateFormat dateFormatter;

  const FinanceTransactionItem({
    super.key,
    required this.record,
    required this.currencyFormatter,
    required this.dateFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (!record.isIncome
                    ? AppColors.error
                    : (FinanceConstants.categoryColors[record.category] ?? AppColors.primary))
                .withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            !record.isIncome
                ? Icons.money_off_rounded
                : FinanceConstants.getCategoryIcon(record.category),
            color: !record.isIncome
                ? AppColors.error
                : (FinanceConstants.categoryColors[record.category] ?? AppColors.primary),
            size: 20,
          ),
        ),
        title: _buildTransactionTitle(record, const TextStyle(fontSize: 13)),
        subtitle: Text(
          dateFormatter.format(record.date),
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencyFormatter.format(record.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: record.isIncome ? AppColors.success : AppColors.error,
              ),
            ),
            if ((record.kartuIdentitas != null &&
                    record.kartuIdentitas!.isNotEmpty) ||
                record.category == 'kamar') ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.badge_outlined,
                    size: 20, color: AppColors.primary),
                tooltip: 'Lihat Kartu Identitas',
                onPressed: () => _showIdentityCard(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTitle(FinanceRecordModel r, TextStyle style) {
    final desc = r.description;
    final cat = r.category;

    // Needs resolution if description is just the bare category name
    final needsResolve = desc == cat || desc == 'kamar';

    if (!needsResolve) {
      return Text(desc, style: style);
    }

    late Future<String> resolver;
    switch (cat) {
      case 'kamar':
      case 'penjualan kamar':
        resolver = FinanceResolverService.resolveRoomName(r);
        break;
      case 'laundry':
        resolver = FinanceResolverService.resolveLaundryDetail(r);
        break;
      case 'motor':
        resolver = FinanceResolverService.resolveMotorDetail(r);
        break;
      default:
        return Text(desc, style: style);
    }

    return FutureBuilder<String>(
      future: resolver,
      builder: (ctx, snap) => Text(snap.data ?? desc, style: style),
    );
  }

  Future<void> _showIdentityCard(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      String? finalUrl = record.kartuIdentitas;
      if (finalUrl == null || finalUrl.isEmpty) {
        final resDocs = await FirebaseFirestore.instance
            .collection('Reservasi')
            .where('total', isEqualTo: record.amount)
            .get();
        for (var doc in resDocs.docs) {
          final data = doc.data();
          final time = (data['created_at'] as Timestamp?)?.toDate();
          if (time != null &&
              time.difference(record.date).abs().inMinutes < 120) {
            final tamuId = data['tamu_id'];
            if (tamuId is String) {
              final tamuDoc = await FirebaseFirestore.instance
                  .collection('Tamu')
                  .doc(tamuId)
                  .get();
              finalUrl = tamuDoc.data()?['kartu_identitas'] as String?;
            } else if (tamuId is DocumentReference) {
              final tamuDoc = await tamuId.get();
              finalUrl = (tamuDoc.data() as Map<String, dynamic>?)?['kartu_identitas']
                  as String?;
            }
            break;
          }
        }
      }

      if (finalUrl == null || finalUrl.isEmpty) {
        throw Exception('Foto KTP tidak tersedia untuk data lama ini.');
      }

      final url = finalUrl.startsWith('http')
          ? finalUrl
          : await FirebaseStorage.instance.ref(finalUrl).getDownloadURL();

      if (!context.mounted) return;
      Navigator.pop(context); // close loading
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Kartu Identitas'),
          content: Image.network(url),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat KTP: $e')),
      );
    }
  }
}
