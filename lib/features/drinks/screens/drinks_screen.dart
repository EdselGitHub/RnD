import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/drinks_provider.dart';
import '../../payment/screens/payment_screen.dart';
import '../../../core/models/drink_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/stat_card.dart';
import '../../../core/constants/app_constants.dart';

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
                      // Existing drink info row
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
                      // Action buttons row
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
    final stokCtrl = TextEditingController(text: '${drink.stok}');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
                      content: Text('Stok ${drink.nama} diubah menjadi $newStok'),
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Minuman'),
        content: Text('Yakin ingin menghapus "${drink.nama}"?'),
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

class AddDrinkScreen extends ConsumerStatefulWidget {
  const AddDrinkScreen({super.key});

  @override
  ConsumerState<AddDrinkScreen> createState() => _AddDrinkScreenState();
}

class _AddDrinkScreenState extends ConsumerState<AddDrinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(drinksNotifierProvider.notifier).addDrink(
            name: _nameCtrl.text.trim(),
            price: double.parse(_priceCtrl.text),
            stock: int.parse(_stockCtrl.text),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Minuman berhasil ditambahkan!'),
            backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Minuman')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Form(
          key: _formKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nama Minuman',
                        prefixIcon: Icon(Icons.local_drink_outlined)),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Harga (Rp)',
                        prefixIcon: Icon(Icons.payments_outlined)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib diisi';
                      if (double.tryParse(v) == null) return 'Angka tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Stok Awal',
                        prefixIcon: Icon(Icons.inventory_2_outlined)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib diisi';
                      if (int.tryParse(v) == null) return 'Angka tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DrinkTransactionScreen extends ConsumerStatefulWidget {
  final String? drinkId;
  final String? drinkName;

  const DrinkTransactionScreen({super.key, this.drinkId, this.drinkName});

  @override
  ConsumerState<DrinkTransactionScreen> createState() =>
      _DrinkTransactionScreenState();
}

class _DrinkTransactionScreenState
    extends ConsumerState<DrinkTransactionScreen> {
  int _quantity = 1;
  final bool _isLoading = false;

  Future<void> _sell(DrinkModel drink) async {
    final total = drink.harga * _quantity;
    
    if (mounted) {
      // Use Future.microtask to avoid '!_debugLocked' error during rebuild
      Future.microtask(() {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              totalAmount: total,
              onPaymentSuccess: () async {
                // Execute the actual sale ONLY after payment is confirmed
                final userModel = await ref.read(currentUserModelProvider.future);
                await ref.read(drinksNotifierProvider.notifier).sellDrink(
                      drink: drink,
                      quantity: _quantity,
                      createdBy: userModel?.name ?? 'Unknown',
                    );
                
                if (context.mounted) {
                  context.go('/drinks');
                }
              },
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final drinksAsync = ref.watch(drinksStreamProvider);
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: Text('Jual ${widget.drinkName ?? 'Minuman'}')),
      body: drinksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (drinks) {
          final drink = drinks.where((d) => d.id == widget.drinkId).firstOrNull;
          if (drink == null) {
            return const Center(child: Text('Minuman tidak ditemukan'));
          }
          final total = drink.harga * _quantity;
          return Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardDrink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  ),
                  child: const Icon(Icons.local_drink_rounded,
                      size: 72, color: AppColors.cardDrink),
                ),
                const SizedBox(height: 20),
                Text(drink.nama,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(currency.format(drink.harga),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text('Stok: ${drink.stok}',
                    style: TextStyle(
                        color: drink.isLowStock
                            ? AppColors.error
                            : AppColors.textSecondary)),
                const SizedBox(height: 32),
                // Quantity selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filled(
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text('$_quantity',
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold)),
                    ),
                    IconButton.filled(
                      onPressed: _quantity < drink.stok
                          ? () => setState(() => _quantity++)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Text('Total: ${currency.format(total)}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (drink.stok < _quantity || _isLoading)
                        ? null
                        : () => _sell(drink),
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Proses Penjualan'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
