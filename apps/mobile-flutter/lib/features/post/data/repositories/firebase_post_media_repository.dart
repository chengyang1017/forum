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
    List<LocalPostImage> images,
  ) async {
    final urls = <String>[];

    for (var index = 0; index < images.length; index++) {
      final image = images[index];
      final objectName =
          '${DateTime.now().microsecondsSinceEpoch}_${index}_${_safeName(image.name)}';
      final ref = _storage.ref().child('posts/$postId/$objectName');

      await ref.putFile(File(image.path));
      urls.add(await ref.getDownloadURL());
    }

    return List.unmodifiable(urls);
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
