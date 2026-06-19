import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance; //membuat instance firebase firestore

  FirebaseFirestore get db => _db; //agar bisa diakses di file lain
}
