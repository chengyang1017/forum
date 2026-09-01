import '../models/local_post_image.dart';

typedef PostUploadProgress = void Function(double progress);

/// Application port for post media persistence.
///
/// Presentation code can select files with any UI/plugin implementation and
/// convert them to [LocalPostImage] before crossing this boundary. Storage
/// vendor details remain inside the data adapter.
abstract interface class PostMediaRepository {
  Future<List<String>> uploadImages(
    String postId,
    List<LocalPostImage> images, {
    PostUploadProgress? onProgress,
  });

  Future<String> uploadInlineImage(String postId, LocalPostImage image);

  Future<String> copyInlineImageToPost(
    String postId,
    String sourceImageUrl, {
    int maxBytes = 15 * 1024 * 1024,
  });

  Future<void> deleteImage(String imageUrl);
}
