import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/motor_provider.dart';
import '../../payment/screens/payment_screen.dart';
import '../../../core/models/motorcycle_model.dart';
import '../../../core/models/motor_rental_model.dart';
import '../../../core/constants/app_constants.dart';

class AddRentalScreen extends ConsumerStatefulWidget {
  final String? motorcycleId;
  final String? plateNumber;

  const AddRentalScreen({super.key, this.motorcycleId, this.plateNumber});

  @override
  ConsumerState<AddRentalScreen> createState() => _AddRentalScreenState();
}

class _AddRentalScreenState extends ConsumerState<AddRentalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  bool _isCustomPrice = false;
  final _customPriceCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _unitCtrl.dispose();
    _customPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart //supaya bisa input data lama
          ? (_startDate ?? now) 
          : (_endDate != null && !_endDate!.isBefore(_startDate ?? now) 
              ? _endDate! 
              : (_startDate?.add(const Duration(days: 1)) ?? now.add(const Duration(days: 1)))),
      firstDate: isStart 
          ? DateTime(2026)  // input data 2026
          : (_startDate?.add(const Duration(days: 1)) ?? now.add(const Duration(days: 1))),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) _endDate = null;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih tanggal sewa dan kembali')));
      return;
    }

    // cek overlap sama seperti di reservasi
    List<MotorRentalModel> rentals = [];
    try {
      rentals = await ref.read(motorRentalsStreamProvider.future);
    } catch (_) {
      // jika error, asumsi kosong / bisa handle
    }

    final isOverlap = rentals.any((res) {
      if (res.motorId != widget.motorcycleId || res.status != 'aktif') {
        return false;
      }
      
      //strip tanggal
      final start1 = DateUtils.dateOnly(_startDate!);
      final end1 = DateUtils.dateOnly(_endDate!);
      final start2 = DateUtils.dateOnly(res.tanggal);
      final end2 = DateUtils.dateOnly(res.tanggalSelesai);

      // overlap: (startDate < res.tanggalSelesai && endDate > res.tanggal)
      return start1.isBefore(end2) && end1.isAfter(start2);
    });

    if (isOverlap) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Motor sudah disewa pada tanggal tersebut. Silakan pilih tanggal lain.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final motorsAsync = ref.read(motorcyclesStreamProvider);
      final motors = motorsAsync.value ?? [];
      final motor = motors.firstWhere(
        (m) => m.id == widget.motorcycleId,
        orElse: () => MotorcycleModel(
            id: widget.motorcycleId ?? '',
            nama: widget.plateNumber ?? '',
            platNumber: widget.plateNumber ?? '',
            harga: 0,
            status: AppStrings.motorAvailable),
      );

      final days = _endDate!.difference(_startDate!).inDays;
      final double totalPrice = _isCustomPrice
          ? (double.tryParse(_customPriceCtrl.text) ?? 0.0)
          : (days * motor.harga).toDouble();

      if (mounted) {
        Future.microtask(() {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentScreen(
                totalAmount: totalPrice,
                onPaymentSuccess: () async {
                  //simpan kalau sudah payment
                  await ref.read(motorNotifierProvider.notifier).addRental(
                        motorcycle: motor,
                        guestName: _nameCtrl.text.trim(),
                        guestPhone: _phoneCtrl.text.trim(),
                        unit: _unitCtrl.text.trim(),
                        startDate: _startDate!,
                        endDate: _endDate!,
                        total: totalPrice,
                      );
                  
                  if (context.mounted) {
                    context.go('/motorcycles');
                  }
                },
              ),
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy', 'id_ID');
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final days =
        (_startDate != null && _endDate != null) ? _endDate!.difference(_startDate!).inDays : 0;

    final motorsAsync = ref.watch(motorcyclesStreamProvider);
    final motors = motorsAsync.value ?? [];
    final motor = motors.firstWhere(
      (m) => m.id == widget.motorcycleId,
      orElse: () => MotorcycleModel(
          id: widget.motorcycleId ?? '',
          nama: widget.plateNumber ?? '',
          platNumber: widget.plateNumber ?? '',
          harga: 0,
          status: AppStrings.motorAvailable),
    );

    final double totalPrice = _isCustomPrice
        ? (double.tryParse(_customPriceCtrl.text) ?? 0.0)
        : (days * motor.harga).toDouble();

    return Scaffold(
      appBar: AppBar(title: Text('Penyewaan Motor ${widget.plateNumber ?? ''}')),
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
                      const Text('Tanggal Sewa',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateBtn('Tanggal Sewa',
                                _startDate != null ? df.format(_startDate!) : 'Pilih',
                                () => _pickDate(true)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDateBtn('Tanggal Kembali',
                                _endDate != null ? df.format(_endDate!) : 'Pilih',
                                () => _pickDate(false)),
                          ),
                        ],
                      ),
                      if (days > 0 || _isCustomPrice)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$days hari',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                              Text('Total: ${currency.format(totalPrice)}',
                                  style: const TextStyle(
                                      color: AppColors.success,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Metode Biaya',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Gunakan Harga Kustom (Manual)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: const Text('Nonaktifkan perhitungan otomatis untuk mengisi harga sendiri', style: TextStyle(fontSize: 11)),
                        value: _isCustomPrice,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (bool value) {
                          setState(() {
                            _isCustomPrice = value;
                            if (!value) {
                              _customPriceCtrl.clear();
                            }
                          });
                        },
                      ),
                      if (_isCustomPrice) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _customPriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Masukkan Harga Total (Rp)',
                            prefixIcon: Icon(Icons.money_rounded),
                            hintText: 'Contoh: 50000',
                          ),
                          onChanged: (val) {
                            setState(() {});
                          },
                          validator: (v) {
                            if (_isCustomPrice && (v == null || v.isEmpty)) {
                              return 'Harga kustom wajib diisi jika mode manual aktif';
                            }
                            if (v != null && double.tryParse(v) == null) {
                              return 'Masukkan angka yang valid';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Data Penyewa',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            prefixIcon: Icon(Icons.person_outlined)),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            labelText: 'No. Telepon',
                            prefixIcon: Icon(Icons.phone_outlined)),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _unitCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Unit / Nomor Kamar',
                            prefixIcon: Icon(Icons.door_front_door_outlined)),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
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
                      : const Text('Simpan Penyewaan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateBtn(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Flexible(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
