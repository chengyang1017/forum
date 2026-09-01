class PostModel {
  final String id;
  final String? userId;
  final String? title;
  final String? content;
  final List<dynamic> bodyDelta;

  // 一级分类。继续保留，兼容当前 Feed 查询与旧帖子。
  final String? category;

  // 当前真正选中的分类节点。
  // 旧帖子没有该字段时由 data mapper 回退到 category。
  final String? categoryId;

  // 从一级分类到当前分类节点的完整路径。
  // 例如: ['medicine', 'internal_medicine', 'cardiology']
  final List<String> categoryPath;

  final String? languageCode;
  final String? primaryLanguageCode;
  final List<String> availableLanguageCodes;
  final List<String>? imageUrls;
  final List<String>? likes;
  final int likeCount;
  final int commentCount;
  final bool isBookmarked;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PostModel({
    required this.id,
    this.userId,
    this.title,
    this.content,
    this.bodyDelta = const [],
    this.category,
    this.categoryId,
    this.categoryPath = const [],
    this.languageCode,
    this.primaryLanguageCode,
    this.availableLanguageCodes = const [],
    this.imageUrls,
    this.likes,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isBookmarked = false,
    this.createdAt,
    this.updatedAt,
  });

  PostModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    List<dynamic>? bodyDelta,
    String? category,
    String? categoryId,
    List<String>? categoryPath,
    String? languageCode,
    String? primaryLanguageCode,
    List<String>? availableLanguageCodes,
    List<String>? imageUrls,
    List<String>? likes,
    int? likeCount,
    int? commentCount,
    bool? isBookmarked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      bodyDelta: bodyDelta ?? this.bodyDelta,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      categoryPath: categoryPath ?? this.categoryPath,
      languageCode: languageCode ?? this.languageCode,
      primaryLanguageCode: primaryLanguageCode ?? this.primaryLanguageCode,
      availableLanguageCodes:
          availableLanguageCodes ?? this.availableLanguageCodes,
      imageUrls: imageUrls ?? this.imageUrls,
      likes: likes ?? this.likes,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
