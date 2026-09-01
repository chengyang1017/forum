import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../auth/data/services/user_api.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/repositories/profile_repository.dart';

/// Data-layer implementation of [ProfileRepository].
///
/// PostgreSQL is authoritative. Firestore remains a best-effort migration
/// mirror for older Firebase-backed features and never decides whether a
/// profile mutation succeeded.
final class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    UserApi? userApi,
    FirebaseFirestore? firestore,
  })  : _userApi = userApi ?? UserApi(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final UserApi _userApi;
  final FirebaseFirestore _firestore;

  @override
  Future<UserModel?> getProfile(String userId) {
    return _userApi.getUser(userId);
  }

  @override
  Future<UserModel> updateTags({
    required String userId,
    required List<String> tags,
  }) async {
    final copiedTags = List<String>.from(tags);
    final user = await _userApi.updateCurrentUser({'tags': copiedTags});
    await _mirror(userId, {'tags': copiedTags});
    return user;
  }

  @override
  Future<UserModel> updateLanguages({
    required String userId,
    required List<Map<String, dynamic>> languages,
  }) async {
    final copiedLanguages = languages
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);

    final user = await _userApi.updateCurrentUser({
      'languages': copiedLanguages,
    });
    await _mirror(userId, {'languages': copiedLanguages});
    return user;
  }

  @override
  Future<UserModel> updateBirthday({
    required String userId,
    required DateTime? birthday,
    required bool showAge,
  }) async {
    final user = await _userApi.updateCurrentUser({
      'birthday': birthday?.toIso8601String(),
      'showAge': showAge,
    });

    await _mirror(userId, {
      'birthday': birthday == null
          ? FieldValue.delete()
          : Timestamp.fromDate(birthday),
      'showAge': showAge,
    });
    return user;
  }

  @override
  Future<UserModel> updateAvatarUrl({
    required String userId,
    required String avatarUrl,
  }) async {
    final user = await _userApi.updateCurrentUser({'avatarUrl': avatarUrl});
    await _mirror(userId, {'avatar': avatarUrl});
    return user;
  }

  @override
  Future<UserModel> updateNickname({
    required String userId,
    required String nickname,
  }) async {
    final user = await _userApi.updateCurrentUser({
      'nickname': nickname.isEmpty ? null : nickname,
    });
    await _mirror(userId, {
      'nickname': nickname.isEmpty ? FieldValue.delete() : nickname,
    });
    return user;
  }

  @override
  Future<UserModel> updateUsername({
    required String userId,
    required String username,
  }) async {
    final user = await _userApi.updateCurrentUser({'username': username});
    await _mirror(userId, {'username': username});
    return user;
  }

  @override
  Future<UserModel> updateBio({
    required String userId,
    required String bio,
  }) async {
    final user = await _userApi.updateCurrentUser({'bio': bio});
    await _mirror(userId, {'bio': bio});
    return user;
  }

  Future<void> _mirror(String userId, Map<String, Object?> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (error) {
      debugPrint('Profile Firestore mirror failed: $error');
    }
  }
}
