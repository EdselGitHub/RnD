import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getUserModel(String uid) async {
    try {
      final doc = await _firestore.collection('Users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, uid);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    if (credential.user == null) return null;
    
    final userModel = await getUserModel(credential.user!.uid);
    
    // Cek apakah akun memiliki role yang diizinkan (admin, owner, karyawan)
    if (userModel != null && !['admin', 'owner', 'karyawan'].contains(userModel.role)) {
      await _auth.signOut();
      throw Exception('Akses ditolak. Role tidak diizinkan.');
    }
    
    return userModel;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
