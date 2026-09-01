import '../models/local_profile_image.dart';

/// Application port for avatar storage.
///
/// The profile feature owns the lifecycle decision while the adapter owns the
/// storage provider implementation.
abstract interface class ProfileMediaRepository {
  Future<String> uploadAvatar({
    required String userId,
    required LocalProfileImage image,
  });

  Future<void> deleteAvatar(String avatarUrl);
}
