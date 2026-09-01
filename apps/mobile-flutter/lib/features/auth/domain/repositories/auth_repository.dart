import '../models/user_model.dart';

/// Domain boundary for authentication and legacy Firebase-backed account data.
///
/// Presentation code depends on this contract and does not know which auth or
/// persistence SDK implements it.
abstract interface class AuthRepository {
  Future<UserModel> login(String email, String password);

  Future<UserModel> register(String email, String password, String username);

  Future<UserModel?> getCurrentUser();

  Future<UserModel> updateProfile(UserModel user);

  Future<void> changePassword(String currentPassword, String newPassword);

  Future<(String uid, String question)?> getSecurityQuestion(String email);

  Future<bool> verifySecurityAnswer(String uid, String answer);

  Future<Set<String>> getLegacyInterests(String userId);

  Future<void> logout();
}
