class DiscoverUser {
  const DiscoverUser({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatarUrl,
  });

  final String id;
  final String username;
  final String nickname;
  final String avatarUrl;

  String get displayName => nickname.isNotEmpty ? nickname : username;
}
