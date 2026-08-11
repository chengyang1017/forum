import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();

  // ========== 登录 ==========
  Future<UserModel> login(String email, String password) async {
    final userCred = await _authService.loginWithEmailPassword(email, password);
    final uid = userCred.user!.uid;

    final userMap = await _authService.getUserData(uid);
    if (userMap == null) {
      throw Exception('用户数据不存在，请重新注册');
    }

    // 检查是否被封禁
    if (userMap['banned'] == true) {
      await _authService.logout();
      throw Exception('账号已被封禁');
    }

    return UserModel.fromJson(userMap);
  }

  // ========== 注册 ==========
  Future<UserModel> register(String email, String password, String username) async {
    final userCred = await _authService.registerWithEmailPassword(email, password);
    final uid = userCred.user!.uid;

    final newUserMap = {
      'uid': uid,
      'username': username,
      'email': email,
      'displayName': username,
      'photoUrl': null,
      'bio': null,
      'friends': [],
      'friendRequests': [],
      'createdAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
      'banned': false,
      'role': 'user',
    };

    await _authService.saveUserData(uid, newUserMap);
    return UserModel.fromJson(newUserMap);
  }

  // ========== 获取当前用户 ==========
  Future<UserModel?> getCurrentUser() async {
    final uid = _authService.currentUserId;
    if (uid == null) return null;

    final userMap = await _authService.getUserData(uid);
    if (userMap == null) return null;

    if (userMap['banned'] == true) {
      await _authService.logout();
      return null;
    }

    return UserModel.fromJson(userMap);
  }

  // ========== 更新用户资料 ==========
  Future<UserModel> updateProfile(UserModel user) async {
    await _authService.updateUserData(user.id, user.toJson());
    final updatedMap = await _authService.getUserData(user.id);
    if (updatedMap == null) {
      throw Exception('更新后获取用户数据失败');
    }
    return UserModel.fromJson(updatedMap);
  }

  // ========== 修改密码 ==========
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _authService.reauthenticate(currentPassword);
      await _authService.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      String msg = '修改失败';
      if (e.code == 'wrong-password') {
        msg = '当前密码错误';
      } else if (e.code == 'weak-password') {
        msg = '新密码太弱，至少6位';
      } else {
        msg = e.message ?? '修改失败';
      }
      throw Exception(msg);
    } catch (e) {
      throw Exception('修改失败: $e');
    }
  }

  // ========== 密保问题（找回密码用） ==========
  Future<(String uid, String question)?> getSecurityQuestion(String email) async {
    final userMap = await _authService.getUserByEmail(email);
    if (userMap == null) return null;
    final question = userMap['securityQuestion'] as String?;
    if (question == null || question.isEmpty) return null;
    return (userMap['uid'] as String, question);
  }

  Future<bool> verifySecurityAnswer(String uid, String answer) async {
    final userMap = await _authService.getUserData(uid);
    if (userMap == null) return false;
    final correctAnswer = userMap['securityAnswer'] ?? '';
    return answer == correctAnswer;
  }

  // ========== 登出 ==========
  Future<void> logout() {
    return _authService.logout();
  }
}