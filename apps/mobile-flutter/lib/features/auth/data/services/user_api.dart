import '../../../../core/network/api_client.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/user_backend_repository.dart';
import '../mappers/user_model_mapper.dart';

class UserApi implements UserBackendRepository {
  UserApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<void> syncCurrentUser(UserModel user) async {
    await _client.put('/users/me', {
      'username': user.username,
      'nickname': user.nickname,
      'avatarUrl': user.avatarUrl.isEmpty ? null : user.avatarUrl,
      'bio': user.bio,
      'showAge': user.showAge,
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final response = await _client.get('/users/me');
    final data = response['user'];

    if (data is! Map) {
      return null;
    }

    return UserModelMapper.fromMap(Map<String, dynamic>.from(data));
  }

  @override
  Future<UserModel> updateCurrentUser(Map<String, dynamic> data) async {
    final response = await _client.patch('/users/me', data);
    final userData = response['user'];

    if (userData is! Map) {
      throw Exception('Invalid user response');
    }

    return UserModelMapper.fromMap(Map<String, dynamic>.from(userData));
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    final response = await _client.get('/users/$uid');
    final data = response['user'];

    if (data is! Map) {
      return null;
    }

    return UserModelMapper.fromMap(Map<String, dynamic>.from(data));
  }

  @override
  Future<({Set<String> interests, bool migrated})> getInterestState() async {
    final response = await _client.get('/users/me/interests');

    return (
      interests: _readInterests(response['interests']),
      migrated: response['migrated'] == true,
    );
  }

  @override
  Future<Set<String>> updateInterests(Set<String> interests) async {
    final response = await _client.put('/users/me/interests', {
      'interests': interests.toList()..sort(),
    });

    return _readInterests(response['interests']);
  }

  @override
  Future<Set<String>> migrateInterests(Set<String> legacyInterests) async {
    final response = await _client.post(
      '/users/me/interests/migrate',
      data: {'interests': legacyInterests.toList()..sort()},
    );

    return _readInterests(response['interests']);
  }

  Set<String> _readInterests(Object? value) {
    if (value is! Iterable) {
      return <String>{};
    }

    return value
        .whereType<String>()
        .map((interest) => interest.trim())
        .where((interest) => interest.isNotEmpty)
        .toSet();
  }
}
