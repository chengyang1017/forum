import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../application/models/local_post_image.dart';
import '../../application/ports/post_media_repository.dart';

/// Firebase Storage adapter for post media.
final class FirebasePostMediaRepository implements PostMediaRepository {
  FirebasePostMediaRepository({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<List<String>> uploadImages(
    String postId,
    List<LocalPostImage> images, {
    PostUploadProgress? onProgress,
  }) async {
    final urls = <String>[];

    for (var index = 0; index < images.length; index++) {
      final image = images[index];
      final objectName =
          '${DateTime.now().microsecondsSinceEpoch}_${index}_${_safeName(image.name)}';
      final ref = _storage.ref().child('posts/$postId/$objectName');
      final uploadTask = ref.putFile(File(image.path));

      await for (final snapshot in uploadTask.snapshotEvents) {
        final totalBytes = snapshot.totalBytes;
        final fileProgress = totalBytes == 0
            ? 0.0
            : snapshot.bytesTransferred / totalBytes;

        onProgress?.call((index + fileProgress) / images.length);
      }

      urls.add(await ref.getDownloadURL());
    }

    return List.unmodifiable(urls);
  }

  @override
  Future<String> uploadInlineImage(String postId, LocalPostImage image) async {
    final objectName =
        '${DateTime.now().microsecondsSinceEpoch}_${_safeName(image.name)}';
    final ref = _storage.ref().child('posts/$postId/inline/$objectName');

    await ref.putFile(File(image.path));

    return ref.getDownloadURL();
  }

  @override
  Future<String> copyInlineImageToPost(
    String postId,
    String sourceImageUrl, {
    int maxBytes = 15 * 1024 * 1024,
  }) async {
    final sourceRef = _storage.refFromURL(sourceImageUrl);
    final currentPostPrefix = 'posts/$postId/';

    if (sourceRef.fullPath.startsWith(currentPostPrefix)) {
      return sourceImageUrl;
    }

    final bytes = await sourceRef.getData(maxBytes);

    if (bytes == null) {
      throw StateError('Unable to read source image');
    }

    final metadata = await sourceRef.getMetadata();
    final objectName =
        'note_${DateTime.now().microsecondsSinceEpoch}_${_safeName(sourceRef.name)}';
    final targetRef = _storage.ref().child('posts/$postId/inline/$objectName');

    await targetRef.putData(
      bytes,
      SettableMetadata(contentType: metadata.contentType),
    );

    return targetRef.getDownloadURL();
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') {
        rethrow;
      }
    }
  }

  String _safeName(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'image';
    }

    return trimmed.replaceAll('/', '_').replaceAll('\\', '_');
  }
}
