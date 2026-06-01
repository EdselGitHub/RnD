
import '../entities/guest_entity.dart';

class GuestModel extends GuestEntity {
  const GuestModel({
    required super.id,
    required super.nama,
    required super.noHp,
    required super.kartuIdentitas,
  });





  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'no_hp': noHp,
      'kartu_identitas': kartuIdentitas,
    };
  }
}
