import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../payment/screens/payment_screen.dart';
import '../providers/reservation_provider.dart';
import '../../../core/models/guest_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';

class AddReservationScreen extends ConsumerStatefulWidget {
  final String? roomId;
  final String? roomNumber;

  const AddReservationScreen({super.key, this.roomId, this.roomNumber});

  @override
  ConsumerState<AddReservationScreen> createState() =>
      _AddReservationScreenState();
}

class _AddReservationScreenState extends ConsumerState<AddReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isCustomPrice = false;
  final _customPriceCtrl = TextEditingController();
  
  XFile? _idCardImage;
  final _imagePicker = ImagePicker();

  DateTime? _checkIn;
  DateTime? _checkOut;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _customPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async { //asal dari image_pciker dependency
    final picked = await _imagePicker.pickImage(source: source); //source ada dua yaitu gallery atau camera
    if (picked != null) {
      setState(() => _idCardImage = picked);
    }
  }

  //untuk menampilkan opsi upload foto ktp / paspor
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusL)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isCheckIn) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      //   initialDate: isCheckIn ? (_checkIn ?? now) : (_checkOut ?? (_checkIn ?? now)),
      // // firstDate: isCheckIn ? now : (_checkIn ?? now),
      // // firstDate: DateTime(now.month - 1),
      // firstDate: DateTime(2026),
      // // lastDate: DateTime(2045),
     // (${df.format(checkIn)} - ${df.format(checkOut)})
     //final df = DateFormat('dd MMM yyyy', 'id_ID');//formarter
      initialDate: isCheckIn 
          ? (_checkIn ?? now) 
          : (_checkOut != null && !_checkOut!.isBefore(_checkIn ?? now) 
              ? _checkOut! 
              : (_checkIn?.add(const Duration(days: 1)) ?? now.add(const Duration(days: 1)))),
      firstDate: isCheckIn 
          ? DateTime(2026) 
          : (_checkIn?.add(const Duration(days: 1)) ?? now.add(const Duration(days: 1))),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) { //pilih ulsng kalo checkout lebih awal
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut != null && _checkOut!.isBefore(_checkIn!)) {
            _checkOut = null;
          }
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_checkIn == null || _checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal check-in dan check-out')),
      );
      return;
    }
    if (_checkOut!.isBefore(_checkIn!) || _checkOut!.isAtSameMomentAs(_checkIn!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal check-out harus setelah tanggal check-in'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_idCardImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mohon lampirkan foto KTP/Kartu Identitas'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    //tampilkan model loading
    setState(() => _isLoading = true);

    try {
      //upload foto ke firebase storage
      String? imageUrl = await StorageService.uploadKartuIdentitas(_idCardImage!);

      if (imageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal upload foto. Silakan coba lagi.'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      //cek apakah tanggal overlap
      final reservationsAsync = ref.read(reservationsStreamProvider);
      final reservations = reservationsAsync.value ?? [];
      
      bool isOverlap = reservations.any((res) {
        if (res.roomId != widget.roomId || res.status != 'aktif') return false;
        //untuk memastikan tanggal sesuai dengan inputan
        final checkInDate = DateUtils.dateOnly(_checkIn!);//dipilih admin
        final checkOutDate = DateUtils.dateOnly(_checkOut!);
        final resCheckin = DateUtils.dateOnly(res.checkin);//sudah ada di database
        final resCheckout = DateUtils.dateOnly(res.checkout);
        //kondisi overlap: (checkIn < res.checkout && checkOut > res.checkin)
        return checkInDate.isBefore(resCheckout) && checkOutDate.isAfter(resCheckin);
      //checkInBaru < checkoutLama  &&  checkOutBaru > checkinLama

      });

      if (isOverlap) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kamar sudah terisi pada tanggal tersebut. Silakan pilih tanggal lain.'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      //getter data ruangan
      final roomsAsync = ref.read(roomsStreamProvider);
      final rooms = roomsAsync.value ?? [];
      final room = rooms.firstWhere(
        (r) => r.id == widget.roomId, //=> return {}
        orElse: () => RoomModel(
            id: widget.roomId ?? '',
            nama: widget.roomNumber ?? '',
            harga: 0,
            status: 'tersedia'),
      );

      final guest = GuestModel(
        id: '',
        nama: _nameCtrl.text.trim(),
        noHp: _phoneCtrl.text.trim(),
        kartuIdentitas: imageUrl, //gunakan URL dari firebase storage
      );

    final nights = _checkOut!.difference(_checkIn!).inDays;
    double totalPrice = 0;

     if (_isCustomPrice) {
      totalPrice = double.tryParse(_customPriceCtrl.text) ?? 0.0;
    } else {
      final nights = _checkOut!.difference(_checkIn!).inDays;
      int remainingNights = nights;
      if (room.hargaBulanan > 0 && remainingNights >= 30) {
        final months = remainingNights ~/ 30;
        totalPrice += months * room.hargaBulanan;
        remainingNights %= 30;
      }
      if (room.hargaMingguan > 0 && remainingNights >= 7) {
        final weeks = remainingNights ~/ 7;
        totalPrice += weeks * room.hargaMingguan;
        remainingNights %= 7;
      }
      totalPrice += remainingNights * room.harga;
    }

    // int remainingNights = nights;

    // if (room.hargaBulanan > 0 && remainingNights >= 30) {
    //   final months = remainingNights ~/ 30;
    //   totalPrice += months * room.hargaBulanan;
    //   remainingNights %= 30;
    // }
    // if (room.hargaMingguan > 0 && remainingNights >= 7) {
    //   final weeks = remainingNights ~/ 7;
    //   totalPrice += weeks * room.hargaMingguan;
    //   remainingNights %= 7;
    // }
    // totalPrice += remainingNights * room.harga;

      if (mounted) {
        Future.microtask(() {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentScreen(
                totalAmount: totalPrice,
                onPaymentSuccess: () async {
                  //simpam ke firebase jika pembayaran selesai
                  await ref.read(reservationNotifierProvider.notifier).addReservation(
                        room: room,
                        guest: guest,
                        checkIn: _checkIn!,
                        checkOut: _checkOut!,
                        total: totalPrice,
                      );
                  
                  if (context.mounted) {
                    context.go('/rooms');
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy', 'id_ID');
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    final nights = (_checkIn != null && _checkOut != null)
        ? _checkOut!.difference(_checkIn!).inDays
        : 0;

    final roomsAsync = ref.watch(roomsStreamProvider);
    final rooms = roomsAsync.value ?? [];
    final room = rooms.firstWhere(
      (r) => r.id == widget.roomId,
      orElse: () => RoomModel(
          id: widget.roomId ?? '',
          nama: widget.roomNumber ?? '',
          harga: 0,
          status: 'tersedia'),
    );

    double totalPrice = 0;

    if (_isCustomPrice) {
      //jika harga kustom akrif, parse dari input text field
      totalPrice = double.tryParse(_customPriceCtrl.text) ?? 0.0;
    } else {

      int remainingNights = nights;

    if (room.hargaBulanan > 0 && remainingNights >= 30) {
      final months = remainingNights ~/ 30; //pembagian bulat
      totalPrice += months * room.hargaBulanan;
      remainingNights %= 30;
    }

    if (room.hargaMingguan > 0 && remainingNights >= 7) {
      final weeks = remainingNights ~/ 7;
      totalPrice += weeks * room.hargaMingguan;
      remainingNights %= 7;
    }
    totalPrice += remainingNights * room.harga;
    }

    // double totalPrice = 0;


    // totalPrice += remainingNights * room.harga;

    return Scaffold(
      appBar: AppBar(title: Text('Reservasi Kamar ${widget.roomNumber ?? ''}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Detail Kamar ${room.nama}'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tipe: ${room.tipe.isEmpty ? '-' : room.tipe}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Harga Harian: ${currency.format(room.harga)}'),
                            if (room.hargaMingguan > 0) Text('Harga Mingguan: ${currency.format(room.hargaMingguan)}'),
                            if (room.hargaBulanan > 0) Text('Harga Bulanan: ${currency.format(room.hargaBulanan)}'),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Lihat Detail Kamar'),
                ),
              ),
              const SizedBox(height: 8),
              //pemilihan date
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tanggal Menginap',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DateButton(
                              label: 'Check-In',
                              date: _checkIn != null ? df.format(_checkIn!) : 'Pilih Tanggal',
                              onTap: () => _pickDate(true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateButton(
                              label: 'Check-Out',
                              date: _checkOut != null ? df.format(_checkOut!) : 'Pilih Tanggal',
                              onTap: () => _pickDate(false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _QuickDateOption(
                              label: '+1 Hari',
                              onTap: () {
                                _checkIn ??= DateTime.now();
                                setState(() => _checkOut = _checkIn!.add(const Duration(days: 1)));
                              },
                            ),
                            const SizedBox(width: 8),
                            _QuickDateOption(
                              label: '+1 Minggu',
                              onTap: () {
                                _checkIn ??= DateTime.now();
                                setState(() => _checkOut = _checkIn!.add(const Duration(days: 7)));
                              },
                            ),
                            const SizedBox(width: 8),
                            _QuickDateOption(
                              label: '+1 Bulan',
                              onTap: () {
                                _checkIn ??= DateTime.now();
                                setState(() => _checkOut = _checkIn!.add(const Duration(days: 30)));
                              },
                            ),
                          ],
                        ),
                      ),
                      if (nights > 0) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$nights malam',
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
                            hintText: 'Contoh: 500000',
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
              //guest data
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
                            labelText: 'Nama Lengkap',
                            prefixIcon: Icon(Icons.person_outlined)),
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            labelText: 'No. Telepon',
                            prefixIcon: Icon(Icons.phone_outlined)),
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text('Foto KTP/Kartu Identitas', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _showImagePickerOptions,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                            child: Container(
                              width: double.infinity,
                              height: 140,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: _idCardImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                                      child: kIsWeb 
                                          ? Image.network(_idCardImage!.path, fit: BoxFit.cover)
                                          : Image.file(File(_idCardImage!.path), fit: BoxFit.cover),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 32),
                                        SizedBox(height: 8),
                                        Text('Ketuk untuk upload foto KTP', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                      ],
                                    ),
                            ),
                          ),
                        ],
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
                      : const Text('Simpan Reservasi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;

  const _DateButton(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14,
                    color: AppColors.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(date,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickDateOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickDateOption({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
