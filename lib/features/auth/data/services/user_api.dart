import '../../../../core/network/api_client.dart';
import '../../domain/models/user_model.dart';

class UserApi {
  UserApi({
    ApiClient? client,
  }) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<void> syncCurrentUser(UserModel user) async {
    await _client.put(
      '/users/me',
      {
        'username': user.username,
        'nickname': user.nickname,
        'avatarUrl':
            user.avatarUrl.isEmpty ? null : user.avatarUrl,
        'bio': user.bio,
        'showAge': user.showAge,
      },
    );
  }

  Future<UserModel?> getCurrentUser() async {
  final response = await _client.get(
    '/users/me',
  );

  final data = response['user'];

  if (data is! Map) {
    return null;
  }

  return UserModel.fromJson(
    Map<String, dynamic>.from(data),
  );
}

Future<UserModel> updateCurrentUser(
  Map<String, dynamic> data,
) async {
  final response = await _client.patch(
    '/users/me',
    data,
  );

  final userData = response['user'];

  if (userData is! Map) {
    throw Exception('Invalid user response');
  }

  return UserModel.fromJson(
    Map<String, dynamic>.from(userData),
  );
}

Future<UserModel?> getUser(String uid) async {
  final response = await _client.get(
    '/users/$uid',
  );

  final data = response['user'];

  if (data is! Map) {
    return null;
  }

  return UserModel.fromJson(
    Map<String, dynamic>.from(data),
  );
}
}