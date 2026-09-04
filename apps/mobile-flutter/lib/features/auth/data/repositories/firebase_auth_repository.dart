import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/errors/auth_failure.dart';
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
    UserCredential credential;
    try {
      credential = await _authService.loginWithEmailPassword(email, password);
    } on FirebaseAuthException catch (error) {
      throw _loginFailure(error);
    } catch (error) {
      throw AuthFailure(AuthFailureCode.loginFailed, cause: error);
    }

    final uid = credential.user?.uid;
    if (uid == null || uid.isEmpty) {
      await _authService.logout();
      throw const AuthFailure(AuthFailureCode.loginFailed);
    }

    final userMap = await _authService.getUserData(uid);
    if (userMap == null) {
      await _authService.logout();
      throw const AuthFailure(AuthFailureCode.userDataMissing);
    }

    if (userMap['banned'] == true) {
      await _authService.logout();
      throw const AuthFailure(AuthFailureCode.accountBanned);
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
    UserCredential credential;
    try {
      credential = await _authService.registerWithEmailPassword(
        email,
        password,
      );
    } on FirebaseAuthException catch (error) {
      throw _registerFailure(error);
    } catch (error) {
      throw AuthFailure(AuthFailureCode.registerFailed, cause: error);
    }

    final uid = credential.user?.uid;
    if (uid == null || uid.isEmpty) {
      throw const AuthFailure(AuthFailureCode.registerFailed);
    }

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

    try {
      await _authService.saveUserData(uid, newUserMap);
    } catch (error) {
      try {
        await credential.user?.delete();
      } catch (cleanupError) {
        debugPrint('Failed to roll back incomplete auth user: $cleanupError');
      }
      throw AuthFailure(AuthFailureCode.registerFailed, cause: error);
    }

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
  Future<void> reauthenticate(String password) async {
    try {
      await _authService.reauthenticate(password);
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'wrong-password':
        case 'invalid-credential':
          throw const AuthFailure(AuthFailureCode.wrongCurrentPassword);
        case 'too-many-requests':
          throw const AuthFailure(AuthFailureCode.tooManyRequests);
        case 'user-disabled':
          throw const AuthFailure(AuthFailureCode.accountDisabled);
        default:
          throw AuthFailure(AuthFailureCode.loginFailed, cause: error);
      }
    } catch (error) {
      if (error is AuthFailure) {
        rethrow;
      }
      throw AuthFailure(AuthFailureCode.loginFailed, cause: error);
    }
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
      switch (error.code) {
        case 'wrong-password':
        case 'invalid-credential':
          throw const AuthFailure(AuthFailureCode.wrongCurrentPassword);
        case 'weak-password':
          throw const AuthFailure(AuthFailureCode.weakPassword);
        case 'too-many-requests':
          throw const AuthFailure(AuthFailureCode.tooManyRequests);
        case 'user-disabled':
          throw const AuthFailure(AuthFailureCode.accountDisabled);
        default:
          throw AuthFailure(AuthFailureCode.changePasswordFailed, cause: error);
      }
    } catch (error) {
      if (error is AuthFailure) {
        rethrow;
      }
      throw AuthFailure(AuthFailureCode.changePasswordFailed, cause: error);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email.trim());
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'invalid-email':
          throw const AuthFailure(AuthFailureCode.invalidEmail);
        case 'too-many-requests':
          throw const AuthFailure(AuthFailureCode.tooManyRequests);
        case 'user-disabled':
          throw const AuthFailure(AuthFailureCode.accountDisabled);
        default:
          throw AuthFailure(AuthFailureCode.resetEmailFailed, cause: error);
      }
    } catch (error) {
      if (error is AuthFailure) {
        rethrow;
      }
      throw AuthFailure(AuthFailureCode.resetEmailFailed, cause: error);
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

  AuthFailure _loginFailure(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => const AuthFailure(AuthFailureCode.invalidEmail),
      'wrong-password' ||
      'invalid-credential' ||
      'user-not-found' => const AuthFailure(AuthFailureCode.invalidCredentials),
      'user-disabled' => const AuthFailure(AuthFailureCode.accountDisabled),
      'too-many-requests' => const AuthFailure(AuthFailureCode.tooManyRequests),
      _ => AuthFailure(AuthFailureCode.loginFailed, cause: error),
    };
  }

  AuthFailure _registerFailure(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => const AuthFailure(AuthFailureCode.invalidEmail),
      'email-already-in-use' => const AuthFailure(
        AuthFailureCode.emailAlreadyInUse,
      ),
      'weak-password' => const AuthFailure(AuthFailureCode.weakPassword),
      'user-disabled' => const AuthFailure(AuthFailureCode.accountDisabled),
      'too-many-requests' => const AuthFailure(AuthFailureCode.tooManyRequests),
      _ => AuthFailure(AuthFailureCode.registerFailed, cause: error),
    };
  }
}
