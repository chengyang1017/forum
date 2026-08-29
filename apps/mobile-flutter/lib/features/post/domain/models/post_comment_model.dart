class PostCommentModel {
  final String id;
  final String? userId;
  final String userName;
  final String? avatarUrl;
  final String text;
  final String? imageUrl;
  final String? replyTo;
  final DateTime? createdAt;
  final List<PostCommentModel> replies;

  const PostCommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.text,
    required this.imageUrl,
    required this.replyTo,
    required this.createdAt,
    required this.replies,
  });

  PostCommentModel copyWith({List<PostCommentModel>? replies}) {
    return PostCommentModel(
      id: id,
      userId: userId,
      userName: userName,
      avatarUrl: avatarUrl,
      text: text,
      imageUrl: imageUrl,
      replyTo: replyTo,
      createdAt: createdAt,
      replies: replies ?? this.replies,
    );
  }

  factory PostCommentModel.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'];

    return PostCommentModel(
      id: json['id']?.toString() ?? '',
      userId: json['uid']?.toString(),
      userName: json['user']?.toString() ?? 'Guest',
      avatarUrl: json['avatarUrl']?.toString(),
      text: json['text']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      replyTo: json['replyTo']?.toString(),
      createdAt: DateTime.tryParse(json['timestamp']?.toString() ?? ''),
      replies: rawReplies is List
          ? rawReplies
                .whereType<Map>()
                .map(
                  (item) => PostCommentModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }
}
