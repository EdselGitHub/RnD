import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/drinks_provider.dart';
import '../../../core/models/drink_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';

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
  bool _isLoading = false;

  Future<void> _sell(DrinkModel drink) async {
    setState(() => _isLoading = true); //loading dan interaksi tombol nonaktif
    try {
      final userModel = await ref.read(currentUserModelProvider.future);
      await ref.read(drinksNotifierProvider.notifier).sellDrink(
            drink: drink,
            quantity: _quantity,
            createdBy: userModel?.name ?? 'Unknown',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Terjual $_quantity ${widget.drinkName}!'),
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
    final drinksAsync = ref.watch(drinksStreamProvider);
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

//fungsi ui minuman yang ada
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
                //pemilihan quantiti
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
