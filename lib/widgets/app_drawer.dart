import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/finance/providers/finance_provider.dart';
import '../core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            accountName: Text(
              userAsync.value?.name ?? 'Karyawan',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(userAsync.value?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (userAsync.value?.name ?? 'K')[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (userAsync.value?.role != AppStrings.rolePetugas) ...[
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    color: AppColors.primary,
                    onTap: () => context.go('/dashboard'),
                  ),
                  const Divider(height: 1),
                  _DrawerItem(
                    icon: Icons.hotel_rounded,
                    title: 'Reservasi Kamar',
                    color: AppColors.cardRoom,
                    onTap: () => context.go('/rooms'),
                  ),
                  _DrawerItem(
                    icon: Icons.two_wheeler_rounded,
                    title: 'Penyewaan Motor',
                    color: AppColors.cardMotor,
                    onTap: () => context.go('/motorcycles'),
                  ),
                  _DrawerItem(
                    icon: Icons.local_laundry_service_rounded,
                    title: 'Laundry',
                    color: AppColors.cardLaundry,
                    onTap: () => context.go('/laundry'),
                  ),
                ],
                _DrawerItem(
                  icon: Icons.cleaning_services_rounded,
                  title: 'Room Service',
                  color: AppColors.secondary,
                  onTap: () => context.go('/room-service'),
                ),
                if (userAsync.value?.role != AppStrings.rolePetugas) ...[
                  _DrawerItem(
                    icon: Icons.local_drink_rounded,
                    title: 'Minuman & Stok',
                    color: AppColors.cardDrink,
                    onTap: () => context.go('/drinks'),
                  ),
                  _DrawerItem(
                    icon: Icons.money_off_rounded,
                    title: 'Pengeluaran',
                    color: AppColors.error,
                    onTap: () {
                      Navigator.pop(context);
                      AppDrawer.showExpenseDialog(context);
                    },
                  ),
                  if (userAsync.value?.role != AppStrings.roleKaryawan)
                    _DrawerItem(
                      icon: Icons.bar_chart_rounded,
                      title: 'Laporan Keuangan',
                      color: AppColors.cardFinance,
                      onTap: () => context.go('/finance'),
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Keluar',
                style: TextStyle(color: AppColors.error)),
            onTap: () => _showLogoutDialog(context, ref),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut(); //keluar dari akun
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  static void showExpenseDialog(BuildContext rootContext) { //pengeluaran
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime selectedExpensDate = DateTime.now();

    showDialog(
      context: rootContext,
      builder: (BuildContext dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            //perlu pakai stateful builder supaya state tanggal didalam dialog diperbarui saat dipilih
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog (
                  title: const Text('Catat Pengeluaran'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: descCtrl,
                        decoration: const InputDecoration(labelText: 'Jenis Pengeluaran'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Nominal Pengeluaran'),
                      ),
                      const SizedBox(height: 16),
                      //baris untuk memilih tanggal pengeluaran 
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              DateFormat('dd MMMM yyyy', 'id_ID').format(selectedExpensDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedExpensDate,
                                firstDate: DateTime(2026),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null){
                                setDialogState((){
                                  selectedExpensDate = picked;
                                });
                              }
                            },
                            child: const Text('Pilih Tanggal')
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: (){
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () async{
                        final desc = descCtrl.text.trim();
                        final amtText = amountCtrl.text.trim();
                        if(desc.isNotEmpty && amtText.isNotEmpty) {
                          final amount = double.tryParse(amtText) ?? 0.0;
                          try{
                            //kirim selectedExpense date ke notofier
                            await ref.read(financeNotifierProvider.notifier).addExpense(desc, amount, selectedExpensDate);
                            //tutup dialog setelah berhasil
                            if (dialogContext.mounted){
                              Navigator.of(dialogContext).pop();
                            }
                          }catch(e){
                            //tampilkan pesan error kalau gagal
                            debugPrint('error menyimpan pengeluaran: $e');
                          }
                        }
                      },
                      child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }
}
