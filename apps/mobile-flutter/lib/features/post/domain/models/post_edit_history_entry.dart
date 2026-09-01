/// Immutable snapshot of a post version stored in edit history.
final class PostEditHistoryEntry {
  const PostEditHistoryEntry({
    required this.languageCode,
    required this.title,
    required this.content,
    required this.bodyDelta,
    required this.imageUrls,
    required this.editedAt,
  });

  factory PostEditHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PostEditHistoryEntry(
      languageCode: json['languageCode']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      bodyDelta:
          (json['bodyDelta'] as List<dynamic>?)?.toList(growable: false) ??
          const <dynamic>[],
      imageUrls:
          (json['imageUrls'] as List<dynamic>?)
              ?.map((value) => value.toString())
              .toList(growable: false) ??
          const <String>[],
      editedAt: DateTime.tryParse(json['editedAt']?.toString() ?? ''),
    );
  }

  final String languageCode;
  final String title;
  final String content;
  final List<dynamic> bodyDelta;
  final List<String> imageUrls;
  final DateTime? editedAt;
}
