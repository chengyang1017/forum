import '../models/local_post_image.dart';

/// Application port for post media persistence.
///
/// Presentation code can select files with any UI/plugin implementation and
/// convert them to [LocalPostImage] before crossing this boundary.
abstract interface class PostMediaRepository {
  Future<List<String>> uploadImages(
    String postId,
    List<LocalPostImage> images,
  );

  Future<void> deleteImage(String imageUrl);
}
