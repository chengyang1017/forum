import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../application/ports/chat_media_repository.dart';

final class FirebaseChatMediaRepository implements ChatMediaRepository {
  FirebaseChatMediaRepository({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<String> uploadImage({
    required String ownerId,
    required Uint8List bytes,
  }) async {
    final normalizedOwnerId = ownerId.trim();
    if (normalizedOwnerId.isEmpty) {
      throw ArgumentError('ownerId cannot be empty');
    }
    if (bytes.isEmpty) {
      throw ArgumentError('image bytes cannot be empty');
    }

    final fileName = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    final reference = _storage.ref().child(
      'chat_images/$normalizedOwnerId/$fileName',
    );

    await reference.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

    return reference.getDownloadURL();
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    final normalizedUrl = imageUrl.trim();
    if (normalizedUrl.isEmpty) {
      return;
    }

    try {
      await _storage.refFromURL(normalizedUrl).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') {
        rethrow;
      }
    }
  }
}
