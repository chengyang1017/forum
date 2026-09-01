/// Typed domain representation of one language-specific post version.
final class PostLanguageVersion {
  const PostLanguageVersion({
    required this.languageCode,
    required this.title,
    required this.content,
    required this.bodyDelta,
    required this.type,
    this.createdAt,
    this.updatedAt,
  });

  final String languageCode;
  final String title;
  final String content;
  final List<dynamic> bodyDelta;
  final String type;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PostLanguageVersion.fromJson(Map<String, dynamic> json) {
    final rawBodyDelta = json['bodyDelta'];

    return PostLanguageVersion(
      languageCode: json['languageCode']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      bodyDelta: rawBodyDelta is List
          ? List<dynamic>.from(rawBodyDelta)
          : const <dynamic>[],
      type: json['type']?.toString() ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
