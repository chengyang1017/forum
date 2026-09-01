import 'user_model.dart';

class SavedAccount {
  const SavedAccount({
    required this.userId,
    required this.email,
    required this.username,
    required this.avatarUrl,
  });

  factory SavedAccount.fromUser(UserModel user) {
    return SavedAccount(
      userId: user.id,
      email: user.email ?? '',
      username: user.profileDisplayName,
      avatarUrl: user.avatarUrl,
    );
  }

  factory SavedAccount.fromMap(Map<String, dynamic> map) {
    return SavedAccount(
      userId: (map['uid'] ?? map['userId'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      username: (map['username'] ?? '用户').toString(),
      avatarUrl: (map['avatar'] ?? map['avatarUrl'] ?? '').toString(),
    );
  }

  final String userId;
  final String email;
  final String username;
  final String avatarUrl;

  Map<String, String> toMap() {
    return <String, String>{
      'uid': userId,
      'email': email,
      'username': username,
      'avatar': avatarUrl,
    };
  }
}
