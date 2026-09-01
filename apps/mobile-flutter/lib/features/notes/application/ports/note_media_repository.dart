import '../models/local_note_image.dart';

/// Application boundary for note media persistence.
///
/// Presentation code owns image selection. Storage SDKs and filesystem access
/// stay inside data adapters.
abstract interface class NoteMediaRepository {
  Future<String> uploadInlineImage({
    required String noteId,
    required String userId,
    required LocalNoteImage image,
  });
}
