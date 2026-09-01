import '../../../auth/domain/models/user_model.dart';

/// Domain boundary for profile reads and profile mutations.
///
/// PostgreSQL is the source of truth. Migration mirrors and transport details
/// belong to the data layer and must not leak through this contract.
abstract interface class ProfileRepository {
  Future<UserModel?> getProfile(String userId);

  Future<UserModel> updateTags({
    required String userId,
    required List<String> tags,
  });

  Future<UserModel> updateLanguages({
    required String userId,
    required List<Map<String, dynamic>> languages,
  });

  Future<UserModel> updateBirthday({
    required String userId,
    required DateTime? birthday,
    required bool showAge,
  });

  Future<UserModel> updateAvatarUrl({
    required String userId,
    required String avatarUrl,
  });

  Future<UserModel> updateNickname({
    required String userId,
    required String nickname,
  });

  Future<UserModel> updateUsername({
    required String userId,
    required String username,
  });

  Future<UserModel> updateBio({
    required String userId,
    required String bio,
  });
}
