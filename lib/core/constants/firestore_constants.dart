/// Firestore collection names used in the application
class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'Users';
  static const String tamu = 'Tamu';
  static const String ruangan = 'Ruangan';
  static const String reservasi = 'Reservasi';
  static const String motor = 'Motor';
  static const String motorSewa = 'Motor_Sewa';
  static const String laundry = 'Laundry';
  static const String cleaningRoom = 'CleaningRoom';
  static const String minuman = 'Minuman';
  static const String pembelianMinuman = 'Pembelian_Minuman';
  static const String transaksiKeuangan = 'Transaksi_Keuangan';
}

///nama constans field firestore
class FirestoreFields {
  FirestoreFields._();

  //umum
  static const String id = 'id';
  static const String status = 'status';
  static const String createdAt = 'createdAt';
  static const String createdAtIndex = 'created_at';

  //users
  static const String name = 'name';
  static const String email = 'email';
  static const String password = 'password';
  static const String role = 'role';

  //tamu
  static const String nama = 'nama';
  static const String noHp = 'no_hp';
  static const String kartuIdentitas = 'kartu_identitas';

  //ruangan
  static const String harga = 'harga';

  //reservasi
  static const String tamuId = 'tamu_id';
  static const String roomId = 'room_id';
  static const String checkin = 'checkin';
  static const String checkout = 'checkout';
  static const String total = 'total';

  //motor
  static const String motorId = 'motor_id';
  static const String tanggal = 'tanggal';

  //motor Sewa
  static const String tanggalKembali = 'tanggal_kembali';
  static const String pembuatan = 'pembuatan';
  static const String hargaPerhari = 'harga_perhari';

  //laundry
  static const String beratKG = 'beratKG';
  static const String hargaPerKG = 'hargaPerKG';
  static const String jenis = 'jenis';
  static const String noKamar = 'no_kamar';

  //room Service / CleaningRoom
  static const String jadwal = 'jadwal';

  //minuman
  static const String stok = 'stok';

  //minuman Transaksi
  static const String minumanId = 'minuman_id';
  static const String qty = 'qty';

  //transaksi Keuangan
  static const String kategori = 'kategori';
  static const String jumlah = 'jumlah';
  static const String tipe = 'tipe';
  static const String userId = 'user_id';
  static const String deskripsi = 'deskripsi';
}
