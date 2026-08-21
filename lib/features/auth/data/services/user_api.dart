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
}