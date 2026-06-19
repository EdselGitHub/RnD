import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/firestore_constants.dart';
import '../constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance; //layanan authentikasi firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  Stream<User?> get authStateChanges => _auth.authStateChanges(); //stream untuk memonitor perubahan status login

  User? get currentUser => _auth.currentUser; //mendapatkan user yang sedang login

  Future<UserModel?> getUserModel(String uid) async {
    try {
      final doc = await _firestore.collection(FirestoreCollections.users).doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, uid);
    } catch (e) {
      return null;
    }
  }

  // FUGNSI sign in
  Future<UserModel?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(), //trim untuk menghapus spasi kosong diawal dan akhir
    );
    if (credential.user == null) return null;
    
    final userModel = await getUserModel(credential.user!.uid);
    
    // Cek apakah akun memiliki role yang diizinkan (admin, owner, karyawan)
    if (userModel != null && ![
      AppStrings.roleAdmin,
      AppStrings.roleOwner,
      AppStrings.roleKaryawan,
      AppStrings.rolePetugas,
    ].contains(userModel.role)) {
      await _auth.signOut();
      throw Exception('Akses ditolak. Role tidak diizinkan.');
    }
    
    return userModel;
  }
}
