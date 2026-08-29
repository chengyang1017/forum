import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== 认证方法 ==========

  // 登录
  Future<UserCredential> loginWithEmailPassword(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // 注册
  Future<UserCredential> registerWithEmailPassword(
    String email,
    String password,
  ) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // 登出
  Future<void> logout() {
    return _auth.signOut();
  }

  // 重新认证（修改密码前需要）
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('未登录');
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  // 更新密码
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('未登录');
    await user.updatePassword(newPassword);
  }

  // ========== Firestore 用户数据方法 ==========

  // 获取用户文档数据（原始 Map）
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  // 根据邮箱查询用户
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.data();
  }

  // 保存用户数据（注册时用）
  Future<void> saveUserData(String uid, Map<String, dynamic> data) {
    return _firestore.collection('users').doc(uid).set(data);
  }

  // 更新用户数据（部分更新）
  Future<void> updateUserData(String uid, Map<String, dynamic> data) {
    return _firestore.collection('users').doc(uid).update(data);
  }

  // ========== 当前用户信息 ==========

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
}
