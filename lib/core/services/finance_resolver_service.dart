import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/finance_record_model.dart';
import '../constants/firestore_constants.dart';

class FinanceResolverService {
  static Future<String> resolveRoomName(FinanceRecordModel r) async {
    try {
      final resDocs = await FirebaseFirestore.instance
          .collection(FirestoreCollections.reservasi)
          .where('total', isEqualTo: r.amount)
          .get();
      for (var doc in resDocs.docs) {
        final data = doc.data();
        final time = (data['created_at'] as Timestamp?)?.toDate();
        if (time != null && time.difference(r.date).abs().inMinutes < 120) {
          final roomId = data['room_id'];
          if (roomId is String) {
            final roomDoc = await FirebaseFirestore.instance
                .collection(FirestoreCollections.ruangan)
                .doc(roomId)
                .get();
            final roomName = roomDoc.data()?['nama'] as String?;
            if (roomName != null) return 'Penjualan kamar $roomName';
          } else if (roomId is DocumentReference) {
            final roomDoc = await roomId.get();
            final roomName =
                (roomDoc.data() as Map<String, dynamic>?)?['nama'] as String?;
            if (roomName != null) return 'Penjualan kamar $roomName';
          }
        }
      }
    } catch (_) {}
    return 'kamar';
  }

  static Future<String> resolveLaundryDetail(FinanceRecordModel r) async {
    try {
      final docs = await FirebaseFirestore.instance
          .collection(FirestoreCollections.laundry)
          .where('harga', isEqualTo: r.amount)
          .get();
      for (var doc in docs.docs) {
        final data = doc.data();

        //check explicit no_kamar field (dari aplikasi ini)
        final noKamar = data['no_kamar'] as String? ?? '';
        if (noKamar.isNotEmpty) {
          return 'Laundry Kamar $noKamar';
        }

        //periksa tamu_id untuk nomor kamar yang tertanam (dari aplikasi tamu: "Laundry [201] - Nama")
        final rawTamuId = data['tamu_id'];
        final tamuIdStr =
            rawTamuId is DocumentReference ? null : rawTamuId as String?;
        if (tamuIdStr != null && tamuIdStr.isNotEmpty) {
          final match = RegExp(r'\[(\d+)\]').firstMatch(tamuIdStr);
          if (match != null) {
            return 'Laundry Kamar ${match.group(1)}';
          }
          //if tamu_id berisi label seperti "Laundry [201] - Name", tampilkan
          if (tamuIdStr.startsWith('Laundry')) {
            return tamuIdStr;
          }
        }

        //try untuk mendapatkan nama tamu dari tamu_id reference
        if (rawTamuId is DocumentReference) {
          try {
            final tamuDoc = await rawTamuId.get();
            final tamuData = tamuDoc.data() as Map<String, dynamic>?;
            final nama = tamuData?['nama'] as String? ?? '';
            if (nama.isNotEmpty) return 'Laundry - $nama';
          } catch (_) {}
        }
      }
    } catch (_) {}
    return 'laundry';
  }

  static Future<String> resolveMotorDetail(FinanceRecordModel r) async {
    try {
      final docs = await FirebaseFirestore.instance
          .collection(FirestoreCollections.motorSewa)
          .where('total', isEqualTo: r.amount)
          .get();
      for (var doc in docs.docs) {
        final data = doc.data();
        final unit = data['unit'] as String? ?? '';

        //get motor name
        final motorRef = data['motor_id'];
        String motorName = '';
        if (motorRef is DocumentReference) {
          try {
            final motorDoc = await motorRef.get();
            motorName =
                (motorDoc.data() as Map<String, dynamic>?)?['nama'] as String? ??
                    '';
          } catch (_) {}
        } else if (motorRef is String && motorRef.isNotEmpty) {
          try {
            final motorDoc = await FirebaseFirestore.instance
                .collection(FirestoreCollections.motor)
                .doc(motorRef)
                .get();
            motorName = motorDoc.data()?['nama'] as String? ?? '';
          } catch (_) {}
        }

        if (motorName.isNotEmpty && unit.isNotEmpty) {
          return 'Sewa motor $motorName (Unit $unit)';
        } else if (motorName.isNotEmpty) {
          return 'Sewa motor $motorName';
        } else if (unit.isNotEmpty) {
          return 'Sewa motor (Unit $unit)';
        }
      }
    } catch (_) {}
    return 'motor';
  }
}
