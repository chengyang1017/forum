import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../mappers/user_model_mapper.dart';
import '../services/auth_service.dart';

/// Firebase-backed implementation of [AuthRepository].
final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  @override
  Future<UserModel> login(String email, String password) async {
    final credential = await _authService.loginWithEmailPassword(
      email,
      password,
    );
    final uid = credential.user!.uid;

    final userMap = await _authService.getUserData(uid);
    if (userMap == null) {
      throw Exception('用户数据不存在，请重新注册');
    }

    if (userMap['banned'] == true) {
      await _authService.logout();
      throw Exception('账号已被封禁');
    }

    try {
      await _authService.recordSuccessfulLogin(uid);
    } catch (error) {
      debugPrint('Legacy lastLogin mirror failed: $error');
    }

    return UserModelMapper.fromMap(userMap);
  }

  @override
  Future<UserModel> register(
    String email,
    String password,
    String username,
  ) async {
    final credential = await _authService.registerWithEmailPassword(
      email,
      password,
    );
    final uid = credential.user!.uid;

    final newUserMap = <String, dynamic>{
      'uid': uid,
      'username': username,
      'email': email,
      'displayName': username,
      'photoUrl': null,
      'bio': null,
      'friends': <String>[],
      'friendRequests': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
      'banned': false,
      'role': 'user',
    };

    await _authService.saveUserData(uid, newUserMap);
    return UserModelMapper.fromMap(newUserMap);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final uid = _authService.currentUserId;
    if (uid == null) {
      return null;
    }

    final userMap = await _authService.getUserData(uid);
    if (userMap == null) {
      return null;
    }

    if (userMap['banned'] == true) {
      await _authService.logout();
      return null;
    }

    return UserModelMapper.fromMap(userMap);
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    await _authService.updateUserData(
      user.id,
      UserModelMapper.toFirestoreMap(user),
    );

    final updatedMap = await _authService.getUserData(user.id);
    if (updatedMap == null) {
      throw Exception('更新后获取用户数据失败');
    }

    return UserModelMapper.fromMap(updatedMap);
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _authService.reauthenticate(currentPassword);
      await _authService.updatePassword(newPassword);
    } on FirebaseAuthException catch (error) {
      var message = '修改失败';
      if (error.code == 'wrong-password' ||
          error.code == 'invalid-credential') {
        message = '当前密码错误';
      } else if (error.code == 'weak-password') {
        message = '新密码太弱，至少6位';
      } else {
        message = error.message ?? '修改失败';
      }
      throw Exception(message);
    } catch (error) {
      throw Exception('修改失败: $error');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email.trim());
    } on FirebaseAuthException catch (error) {
      if (error.code == 'invalid-email') {
        throw Exception('邮箱格式不正确');
      }
      if (error.code == 'too-many-requests') {
        throw Exception('请求过于频繁，请稍后再试');
      }
      throw Exception(error.message ?? '发送重置邮件失败');
    }
  }

  @override
  Future<Set<String>> getLegacyInterests(String userId) async {
    final userMap = await _authService.getUserData(userId);
    final value = userMap?['interests'];
    if (value is! Iterable) {
      return <String>{};
    }

    return value
        .whereType<String>()
        .map((interest) => interest.trim())
        .where((interest) => interest.isNotEmpty)
        .toSet();
  }

  @override
  Future<void> logout() {
    return _authService.logout();
  }
}
