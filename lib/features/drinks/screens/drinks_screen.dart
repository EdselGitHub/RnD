import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/drinks_provider.dart';
import '../../../core/models/drink_model.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/stat_card.dart';
import '../../../core/constants/app_constants.dart';
import 'add_drink_screen.dart';

class DrinksScreen extends ConsumerWidget {
  const DrinksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drinksAsync = ref.watch(drinksStreamProvider);
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minuman & Stok'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {},
            tooltip: 'Riwayat Transaksi',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: drinksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (drinks) {
          if (drinks.isEmpty) {
            return const EmptyState(
                message: 'Belum ada data minuman',
                icon: Icons.local_drink_outlined);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: drinks.length,
            itemBuilder: (_, i) {
              final d = drinks[i];
              final isLow = d.isLowStock;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    children: [
                      //info minuman dan stok
                      InkWell(
                        onTap: () => context.push('/drinks/transaction',
                            extra: {'drinkId': d.id, 'drinkName': d.nama}),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: isLow
                                    ? AppColors.warning.withOpacity(0.12)
                                    : AppColors.cardDrink.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                              ),
                              child: Icon(Icons.local_drink_rounded,
                                  color: isLow ? AppColors.warning : AppColors.cardDrink),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(d.nama,
                                            style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                      if (isLow) ...[
                                        const SizedBox(width: 6),
                                        const StatusBadge(
                                            label: 'Stok Rendah!', color: AppColors.warning),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(currency.format(d.harga),
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text('${d.stok}',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: isLow ? AppColors.warning : AppColors.textPrimary)),
                                const Text('stok', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 20),
                      //button baris
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _showEditStokDialog(context, ref, d),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                                    SizedBox(width: 6),
                                    Text('Edit Stok',
                                        style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(width: 1, height: 24, color: Colors.grey.shade200),
                          Expanded(
                            child: InkWell(
                              onTap: () => _showDeleteDialog(context, ref, d),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.delete_outlined, size: 16, color: AppColors.error),
                                    SizedBox(width: 6),
                                    Text('Hapus',
                                        style: TextStyle(
                                            color: AppColors.error,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddDrinkScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditStokDialog(BuildContext context, WidgetRef ref, DrinkModel drink) {
    _showPasswordDialog(context, onVerified: () {
      _showStokInputDialog(context, ref, drink);
    });
  }

  void _showPasswordDialog(BuildContext context,
      {required VoidCallback onVerified}) {
    final passCtrl = TextEditingController();
    bool obscure = true;
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.lock_outline, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Verifikasi Password'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Masukkan password untuk mengubah stok.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                obscureText: obscure,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.password_outlined),
                  errorText: errorText,
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
                onSubmitted: (_) => _verifyAndProceed(
                  ctx, passCtrl, onVerified, setState, (err) => errorText = err,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Konfirmasi'),
              onPressed: () => _verifyAndProceed(
                ctx, passCtrl, onVerified, setState, (err) => errorText = err,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _verifyAndProceed(
    BuildContext ctx,
    TextEditingController passCtrl,
    VoidCallback onVerified,
    StateSetter setState,
    void Function(String?) setError,
  ) {
    if (passCtrl.text == '438438') {
      Navigator.pop(ctx);
      onVerified();
    } else {
      setState(() => setError('Password salah, coba lagi'));
    }
  }

  void _showStokInputDialog(
      BuildContext context, WidgetRef ref, DrinkModel drink) {
    final stokCtrl = TextEditingController(text: '${drink.stok}');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Stok - ${drink.nama}'),
        content: TextField(
          controller: stokCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Stok Baru',
            prefixIcon: Icon(Icons.inventory_2_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStok = int.tryParse(stokCtrl.text);
              if (newStok == null || newStok < 0) return;
              await ref
                  .read(drinksNotifierProvider.notifier)
                  .updateStock(drink.id, newStok);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Stok ${drink.nama} diubah menjadi $newStok'),
                      backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }


  void _showDeleteDialog(BuildContext context, WidgetRef ref, DrinkModel drink) {
    _showPasswordDialog(context, onVerified: () {
      _showDeleteConfirmDialog(context, ref, drink);
    });
  }

  void _showDeleteConfirmDialog(
      BuildContext context, WidgetRef ref, DrinkModel drink) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline, color: AppColors.error),
            SizedBox(width: 8),
            Text('Hapus Minuman'),
          ],
        ),
        content: Text('Yakin ingin menghapus "${drink.nama}"?\nTindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref
                  .read(drinksNotifierProvider.notifier)
                  .deleteDrink(drink.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('${drink.nama} berhasil dihapus'),
                      backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
