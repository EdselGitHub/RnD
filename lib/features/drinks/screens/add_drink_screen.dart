import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/drinks_provider.dart';
import '../../../core/constants/app_constants.dart';

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
