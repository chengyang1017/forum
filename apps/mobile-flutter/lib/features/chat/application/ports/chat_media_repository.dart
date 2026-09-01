import 'dart:typed_data';

/// Application boundary for chat media storage.
///
/// Presentation supplies platform-neutral bytes while Firebase Storage stays
/// behind the concrete data-layer adapter.
abstract interface class ChatMediaRepository {
  Future<String> uploadImage({
    required String ownerId,
    required Uint8List bytes,
  });

  Future<void> deleteImage(String imageUrl);
}
