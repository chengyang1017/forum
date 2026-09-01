/// Cleanup plan for media touched while editing a post.
///
/// The editor uploads new media before the post transaction is committed so
/// it can render previews immediately. This plan separates two lifecycles:
///
/// - [newUploadUrls] are safe to delete when the edit is abandoned.
/// - [cleanupAfterSaveUrls] are no longer referenced after a successful save.
final class PostEditMediaCleanupPlan {
  const PostEditMediaCleanupPlan({
    required this.newUploadUrls,
    required this.cleanupAfterSaveUrls,
  });

  final List<String> newUploadUrls;
  final List<String> cleanupAfterSaveUrls;

  factory PostEditMediaCleanupPlan.fromEdit({
    required List<String> originalTopImageUrls,
    required List<dynamic> originalBodyDelta,
    required List<String> currentTopImageUrls,
    required List<dynamic> currentBodyDelta,
    required Iterable<String> newUploadUrls,
  }) {
    final before = <String>{
      ..._normalizedUrls(originalTopImageUrls),
      ...inlineImageUrls(originalBodyDelta),
    };

    final after = <String>{
      ..._normalizedUrls(currentTopImageUrls),
      ...inlineImageUrls(currentBodyDelta),
    };

    final uploads = <String>{..._normalizedUrls(newUploadUrls)};

    final cleanupAfterSave = <String>{
      ...before.difference(after),
      ...uploads.difference(after),
    };

    return PostEditMediaCleanupPlan(
      newUploadUrls: List<String>.unmodifiable(uploads),
      cleanupAfterSaveUrls: List<String>.unmodifiable(cleanupAfterSave),
    );
  }

  static Set<String> inlineImageUrls(List<dynamic> delta) {
    final urls = <String>{};

    for (final operation in delta) {
      if (operation is! Map) {
        continue;
      }

      final insert = operation['insert'];

      if (insert is! Map || !insert.containsKey('image')) {
        continue;
      }

      final value = insert['image'];

      if (value is! String) {
        continue;
      }

      final normalized = value.trim();

      if (normalized.isNotEmpty) {
        urls.add(normalized);
      }
    }

    return urls;
  }

  static Iterable<String> _normalizedUrls(Iterable<String> urls) sync* {
    for (final url in urls) {
      final normalized = url.trim();

      if (normalized.isNotEmpty) {
        yield normalized;
      }
    }
  }
}
