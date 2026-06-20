import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/finance_record_model.dart';
import '../../../core/constants/finance_constants.dart';
import '../../../core/services/finance_resolver_service.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/finance_provider.dart';

class FinanceTransactionItem extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);
    final isAdminOrOwner = userAsync.value?.role == AppStrings.roleAdmin ||
        userAsync.value?.role == AppStrings.roleOwner;

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
            if (isAdminOrOwner) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.error),
                tooltip: 'Hapus Transaksi',
                onPressed: () => _showDeleteConfirmation(context, ref),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus data keuangan ini? Jumlah saldo laporan akan berkurang otomatis.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx); //close dialog

              //tunjukkan loading notification
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menghapus data keuangan...'),
                  duration: Duration(seconds: 1),
                ),
              );

              try {
                await ref
                    .read(financeNotifierProvider.notifier)
                    .deleteTransaction(record);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data keuangan berhasil dihapus!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus data: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTitle(FinanceRecordModel r, TextStyle style) {
    final desc = r.description;
    final cat = r.category;

    //perlu dicari detailnya jika deskripsi hanya berupa nama kategori saja
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
            .collection(FirestoreCollections.reservasi)
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
                  .collection(FirestoreCollections.tamu)
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
      Navigator.pop(context); //tutup loading
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
      Navigator.pop(context); // tutup loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat KTP: $e')),
      );
    }
  }
}
