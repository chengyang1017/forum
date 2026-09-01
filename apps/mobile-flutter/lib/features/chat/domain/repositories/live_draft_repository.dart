import '../models/live_draft.dart';

/// Domain boundary for ephemeral realtime typing previews.
///
/// Realtime Database paths, disconnect handlers, and debounce timers stay in
/// the data adapter rather than leaking into presentation code.
abstract interface class LiveDraftRepository {
  Future<void> prepare({required String chatId, required String userId});

  void updateDraft({
    required String chatId,
    required String userId,
    required String text,
  });

  Stream<List<LiveDraft>> watchDrafts({
    required String chatId,
    required String currentUserId,
  });

  Future<void> clearDraft({required String chatId, required String userId});
}
