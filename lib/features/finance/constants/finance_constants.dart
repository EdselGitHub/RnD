import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class FinanceConstants {
  static const List<String> categories = [
    'penjualan kamar',
    'kamar',
    'motor',
    'laundry',
    'minuman',
    'pengeluaran'
  ];

  static const Map<String, Color> categoryColors = {
    'penjualan kamar': AppColors.cardRoom,
    'kamar': AppColors.cardRoom,
    'motor': AppColors.cardMotor,
    'laundry': AppColors.cardLaundry,
    'minuman': AppColors.cardDrink,
    'pengeluaran': AppColors.error,
  };

  static const Map<String, String> categoryLabels = {
    'penjualan kamar': 'Kamar',
    'kamar': 'Kamar',
    'motor': 'Motor',
    'laundry': 'Laundry',
    'minuman': 'Minuman',
    'pengeluaran': 'Pengeluaran',
  };

  static IconData getCategoryIcon(String category) {
    if (category == 'pengeluaran') return Icons.money_off_rounded;
    switch (category) {
      case 'penjualan kamar':
      case 'kamar':
        return Icons.hotel_rounded;
      case 'motor':
        return Icons.two_wheeler_rounded;
      case 'laundry':
        return Icons.local_laundry_service_rounded;
      case 'minuman':
        return Icons.local_drink_rounded;
      default:
        return Icons.payments_rounded;
    }
  }
}
