import 'package:flutter/material.dart';

///kumpulan warna aplikasi RnD Dewi Sri Bali. //0xFF+hex
class AppColors {
  // primary - bali red oren
  static const Color primary = Color(0xFFE55A2B);
  static const Color primaryLight = Color(0xFFFF8A65);
  static const Color primaryDark = Color(0xFFC44420);
  static const Color primaryDeep = Color(0xFF8B1A0A);

  //secondary - tropical green
  static const Color secondary = Color(0xFF2E7D32);
  static const Color secondaryLight = Color(0xFF66BB6A);

  //background
  static const Color background = Color(0xFFF5F5F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F4F0);

  // status colors
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFB8C00);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF1E88E5);

  // status badge colors
  static const Color available = Color(0xFF43A047);
  static const Color occupied = Color(0xFFE53935);
  static const Color processing = Color(0xFFFB8C00);
  static const Color done = Color(0xFF43A047);

  // text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  //card stats
  static const Color cardRoom = Color(0xFF5C6BC0);
  static const Color cardMotor = Color(0xFF26A69A);
  static const Color cardLaundry = Color(0xFF8D6E63);
  static const Color cardDrink = Color(0xFF42A5F5);
  static const Color cardFinance = Color(0xFF66BB6A);
}

///kumpulan string/label statis yang digunakan di seluruh aplikasi.
class AppStrings {
  static const String appName = 'RnD Dewi Sri';
  static const String appSubtitle = 'Manajemen Penginapan Bali';

  // Auth
  static const String login = 'Masuk';
  static const String logout = 'Keluar';
  static const String email = 'Email';
  static const String password = 'Password';

  // roles
  static const String roleAdmin = 'admin';
  static const String roleOwner = 'owner';
  static const String roleKaryawan = 'karyawan';
  static const String rolePetugas = 'petugas';


  // room status
  static const String roomAvailable = 'Tersedia';
  static const String roomOccupied = 'Terisi';

  // motor status
  static const String motorAvailable = 'Tersedia';
  static const String motorRented = 'Disewa';
  static const String motorDelete = 'Dihapus';

  // laundry status
  static const String laundryProcessing = 'Diproses';
  static const String laundryDone = 'Selesai';
  static const String laundryWaiting = 'Menunggu';

  //room service status
  static const String rsWaiting = 'Menunggu';
  static const String rsDone = 'Selesai';
  static const String rsProses = 'Proses';
}

///konstanta dimensi (padding, radius, icon size) yang digunakan di seluruh aplikasi
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
