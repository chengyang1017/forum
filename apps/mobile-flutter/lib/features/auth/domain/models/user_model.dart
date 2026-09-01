class UserModel {
  final String id;
  final String username;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? nickname;
  final String? avatar;
  final String? bio;
  final List<String>? friends;
  final List<String>? friendRequests;
  final List<String>? tags;
  final List<Map<String, dynamic>>? languages;
  final DateTime? birthday;
  final bool showAge;
  final DateTime? createdAt;
  final DateTime? lastActive;

  const UserModel({
    required this.id,
    required this.username,
    this.email,
    this.displayName,
    this.photoUrl,
    this.nickname,
    this.avatar,
    this.bio,
    this.friends,
    this.friendRequests,
    this.tags,
    this.languages,
    this.birthday,
    this.showAge = true,
    this.createdAt,
    this.lastActive,
  });

  String get avatarUrl {
    final avatarValue = avatar ?? '';
    if (avatarValue.isNotEmpty) {
      return avatarValue;
    }
    return photoUrl ?? '';
  }

  String get profileDisplayName {
    final nicknameValue = nickname ?? '';
    if (nicknameValue.isNotEmpty) {
      return nicknameValue;
    }

    final displayNameValue = displayName ?? '';
    if (displayNameValue.isNotEmpty) {
      return displayNameValue;
    }

    return username;
  }

  String get nicknameText => nickname ?? '';
  String get bioText => bio ?? '';
  List<String> get tagsList => tags ?? const <String>[];
  List<Map<String, dynamic>> get languageList =>
      languages ?? const <Map<String, dynamic>>[];

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? photoUrl,
    String? nickname,
    String? avatar,
    String? bio,
    List<String>? friends,
    List<String>? friendRequests,
    List<String>? tags,
    List<Map<String, dynamic>>? languages,
    DateTime? birthday,
    bool clearBirthday = false,
    bool? showAge,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      friends: friends ?? this.friends,
      friendRequests: friendRequests ?? this.friendRequests,
      tags: tags ?? this.tags,
      languages: languages ?? this.languages,
      birthday: clearBirthday ? null : birthday ?? this.birthday,
      showAge: showAge ?? this.showAge,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
