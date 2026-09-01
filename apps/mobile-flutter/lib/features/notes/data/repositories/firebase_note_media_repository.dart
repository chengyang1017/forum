import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../application/models/local_note_image.dart';
import '../../application/ports/note_media_repository.dart';

final class FirebaseNoteMediaRepository implements NoteMediaRepository {
  FirebaseNoteMediaRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<String> uploadInlineImage({
    required String noteId,
    required String userId,
    required LocalNoteImage image,
  }) async {
    final imageReference = _firestore
        .collection('notes')
        .doc(noteId)
        .collection('images')
        .doc();
    final extension = _imageExtension(
      image.name.isNotEmpty ? image.name : image.path,
    );
    final storagePath = 'note_images/$noteId/${imageReference.id}.$extension';
    final storageReference = _storage.ref(storagePath);
    final file = File(image.path);

    try {
      await storageReference.putFile(
        file,
        SettableMetadata(contentType: _contentType(extension)),
      );

      final imageUrl = await storageReference.getDownloadURL();

      await imageReference.set({
        'url': imageUrl,
        'storagePath': storagePath,
        'uploaderId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return imageUrl;
    } catch (_) {
      try {
        await imageReference.delete();
      } catch (_) {}

      try {
        await storageReference.delete();
      } catch (_) {}

      rethrow;
    }
  }

  String _imageExtension(String path) {
    final parts = path.split('.');
    if (parts.length < 2) {
      return 'jpg';
    }

    final extension = parts.last.toLowerCase();
    const allowedExtensions = <String>{'jpg', 'jpeg', 'png', 'webp'};
    return allowedExtensions.contains(extension) ? extension : 'jpg';
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
