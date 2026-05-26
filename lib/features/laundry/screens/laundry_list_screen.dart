import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/laundry_provider.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/stat_card.dart';
import '../../../core/constants/app_constants.dart';

class LaundryListScreen extends ConsumerWidget {
  const LaundryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laundryAsync = ref.watch(laundryStreamProvider);
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Laundry')),
      drawer: const AppDrawer(),
      body: laundryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return const EmptyState(
                message: 'Belum ada order laundry',
                icon: Icons.local_laundry_service_outlined);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final o = orders[i];
              final isSelesai = o.status == 'selesai';
              final isProses = o.status == 'proses';
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Laundry #${o.id.substring(0, 6)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          StatusBadge(
                            label: isSelesai
                                ? 'Selesai'
                                : isProses
                                    ? 'Proses'
                                    : 'Menunggu',
                            color: isSelesai
                                ? AppColors.success
                                : isProses
                                    ? AppColors.warning
                                    : AppColors.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${o.jenis} • ${o.beratKG} kg',
                          style: const TextStyle(color: AppColors.textSecondary)),
                      Text('Harga/kg: ${currency.format(o.hargaPerKG)}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(currency.format(o.harga),
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (!isSelesai)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (o.status == 'menunggu')
                                  TextButton.icon(
                                    onPressed: () async {
                                      await ref
                                          .read(laundryNotifierProvider.notifier)
                                          .markProses(o.id);
                                    },
                                    icon: const Icon(Icons.play_arrow, size: 16),
                                    label: const Text('Proses'),
                                  ),
                                if (isProses)
                                  TextButton.icon(
                                    onPressed: () async {
                                      await ref
                                          .read(laundryNotifierProvider.notifier)
                                          .markDone(o.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('Laundry selesai!'),
                                              backgroundColor: AppColors.success),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.check_circle, size: 16),
                                    label: const Text('Selesai'),
                                  ),
                              ],
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
            MaterialPageRoute(builder: (_) => const AddLaundryScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddLaundryScreen extends ConsumerStatefulWidget {
  const AddLaundryScreen({super.key});

  @override
  ConsumerState<AddLaundryScreen> createState() => _AddLaundryScreenState();
}

class _AddLaundryScreenState extends ConsumerState<AddLaundryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String _serviceType = 'regular';
  final double _hargaPerKG = 15000;
  bool _isLoading = false;

  final _services = ['regular', 'express', 'dry clean'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _idCtrl.dispose();
    _roomCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(laundryNotifierProvider.notifier).addOrder(
            guestName: _nameCtrl.text.trim(),
            guestPhone: _phoneCtrl.text.trim(),
            guestIdNumber: _idCtrl.text.trim(),
            roomNumber: _roomCtrl.text.trim(),
            serviceType: _serviceType,
            weight: double.parse(_weightCtrl.text),
            hargaPerKG: _hargaPerKG,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Order laundry berhasil disimpan!'),
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
    final weight = double.tryParse(_weightCtrl.text) ?? 0;
    final estimatedPrice = weight * _hargaPerKG;
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Order Laundry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Data Tamu',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Nama Tamu',
                            prefixIcon: Icon(Icons.person_outlined)),
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            labelText: 'No. HP',
                            prefixIcon: Icon(Icons.phone_outlined)),
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _idCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Kartu Identitas',
                            prefixIcon: Icon(Icons.badge_outlined)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _roomCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Nomor Kamar',
                            prefixIcon: Icon(Icons.meeting_room_outlined)),
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Detail Laundry',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _serviceType,
                        decoration: const InputDecoration(labelText: 'Jenis Layanan'),
                        items: _services
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _serviceType = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Berat (kg)',
                            prefixIcon: Icon(Icons.scale_outlined)),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Wajib diisi';
                          if (double.tryParse(v) == null) return 'Angka tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Harga/kg: ${currency.format(_hargaPerKG)}'),
                            Text('Total: ${currency.format(estimatedPrice)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
