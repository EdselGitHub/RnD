import 'package:flutter/material.dart';

class AppColors {
  // Primary - Bali Red/Orange
  static const Color primary = Color(0xFFE55A2B);
  static const Color primaryLight = Color(0xFFFF8A65);
  static const Color primaryDark = Color(0xFFC44420);

  // Secondary - Tropical Green
  static const Color secondary = Color(0xFF2E7D32);
  static const Color secondaryLight = Color(0xFF66BB6A);

  // Background
  static const Color background = Color(0xFFF5F5F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F4F0);

  // Status Colors
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFB8C00);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF1E88E5);

  // Status badge colors
  static const Color available = Color(0xFF43A047);
  static const Color occupied = Color(0xFFE53935);
  static const Color processing = Color(0xFFFB8C00);
  static const Color done = Color(0xFF43A047);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Card stats
  static const Color cardRoom = Color(0xFF5C6BC0);
  static const Color cardMotor = Color(0xFF26A69A);
  static const Color cardLaundry = Color(0xFF8D6E63);
  static const Color cardDrink = Color(0xFF42A5F5);
  static const Color cardFinance = Color(0xFF66BB6A);
}

class AppStrings {
  static const String appName = 'RnD Dewi Sri';
  static const String appSubtitle = 'Manajemen Penginapan Bali';

  // Auth
  static const String login = 'Masuk';
  static const String logout = 'Keluar';
  static const String email = 'Email';
  static const String password = 'Password';

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleOwner = 'owner';
  static const String roleKaryawan = 'karyawan';

  // Room Status
  static const String roomAvailable = 'Tersedia';
  static const String roomOccupied = 'Terisi';

  // Motor Status
  static const String motorAvailable = 'Tersedia';
  static const String motorRented = 'Disewa';

  // Laundry Status
  static const String laundryProcessing = 'Diproses';
  static const String laundrydone = 'Selesai';

  // Room Service Status
  static const String rsWaiting = 'Menunggu';
  static const String rsDone = 'Selesai';
}

class AppDimensions {
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  static const double cardElevation = 2.0;
  static const double iconSizeS = 18.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
}
