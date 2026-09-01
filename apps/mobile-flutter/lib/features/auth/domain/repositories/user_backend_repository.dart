import '../models/user_model.dart';

/// Domain boundary for the server-backed user/profile API.
abstract interface class UserBackendRepository {
  Future<void> syncCurrentUser(UserModel user);

  Future<UserModel?> getCurrentUser();

  Future<UserModel> updateCurrentUser(Map<String, dynamic> data);

  Future<UserModel?> getUser(String uid);

  Future<({Set<String> interests, bool migrated})> getInterestState();

  Future<Set<String>> updateInterests(Set<String> interests);

  Future<Set<String>> migrateInterests(Set<String> legacyInterests);
}
