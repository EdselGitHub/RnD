
class GuestModel {
  final String id;
  final String nama;
  final String noHp;
  final String kartuIdentitas;

  const GuestModel({
    required this.id,
    required this.nama,
    required this.noHp,
    required this.kartuIdentitas,
  });





  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'no_hp': noHp,
      'kartu_identitas': kartuIdentitas,
    };
  }
}
