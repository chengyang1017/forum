import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> loginWithEmailPassword(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmailPassword(
    String email,
    String password,
  ) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() {
    return _auth.signOut();
  }

  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('未登录');
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw StateError('当前账号没有可用邮箱');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('未登录');
    }
    await user.updatePassword(newPassword);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    return doc.data();
  }

  Future<void> saveUserData(String uid, Map<String, dynamic> data) {
    return _firestore.collection('users').doc(uid).set(data);
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) {
    return _firestore.collection('users').doc(uid).update(data);
  }

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
}
