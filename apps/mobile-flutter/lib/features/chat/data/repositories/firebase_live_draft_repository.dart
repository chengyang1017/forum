import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/live_draft.dart';
import '../../domain/repositories/live_draft_repository.dart';

final class FirebaseLiveDraftRepository implements LiveDraftRepository {
  FirebaseLiveDraftRepository({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  static const Duration _writeDebounce = Duration(milliseconds: 150);

  final FirebaseDatabase _database;
  final Map<String, Timer> _writeTimers = <String, Timer>{};

  DatabaseReference _draftRef({
    required String chatId,
    required String userId,
  }) {
    return _database.ref('chatDrafts/$chatId/$userId');
  }

  String _timerKey({required String chatId, required String userId}) {
    return '$chatId::$userId';
  }

  @override
  Future<void> prepare({required String chatId, required String userId}) async {
    await _draftRef(chatId: chatId, userId: userId).onDisconnect().remove();
  }

  @override
  void updateDraft({
    required String chatId,
    required String userId,
    required String text,
  }) {
    final key = _timerKey(chatId: chatId, userId: userId);
    _writeTimers.remove(key)?.cancel();

    if (text.trim().isEmpty) {
      unawaited(clearDraft(chatId: chatId, userId: userId));
      return;
    }

    _writeTimers[key] = Timer(_writeDebounce, () async {
      _writeTimers.remove(key);
      try {
        await _draftRef(
          chatId: chatId,
          userId: userId,
        ).set({'text': text, 'updatedAt': ServerValue.timestamp});
      } catch (error) {
        debugPrint('实时草稿写入失败：$error');
      }
    });
  }

  @override
  Stream<List<LiveDraft>> watchDrafts({
    required String chatId,
    required String currentUserId,
  }) {
    return _database.ref('chatDrafts/$chatId').onValue.map((event) {
      final rawValue = event.snapshot.value;
      if (rawValue is! Map) {
        return <LiveDraft>[];
      }

      final drafts = <LiveDraft>[];
      for (final entry in rawValue.entries) {
        final userId = entry.key.toString();
        if (userId == currentUserId) {
          continue;
        }

        final rawDraft = entry.value;
        if (rawDraft is! Map) {
          continue;
        }

        final draftData = Map<Object?, Object?>.from(rawDraft);
        final text = draftData['text']?.toString().trim() ?? '';
        final updatedAt =
            int.tryParse(draftData['updatedAt']?.toString() ?? '') ?? 0;
        if (text.isEmpty) {
          continue;
        }

        drafts.add(LiveDraft(userId: userId, text: text, updatedAt: updatedAt));
      }

      drafts.sort(
        (first, second) => second.updatedAt.compareTo(first.updatedAt),
      );
      return drafts;
    }).asBroadcastStream();
  }

  @override
  Future<void> clearDraft({
    required String chatId,
    required String userId,
  }) async {
    final key = _timerKey(chatId: chatId, userId: userId);
    _writeTimers.remove(key)?.cancel();

    try {
      await _draftRef(chatId: chatId, userId: userId).remove();
    } catch (error) {
      debugPrint('实时草稿删除失败：$error');
    }
  }
}
