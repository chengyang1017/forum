import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/live_draft.dart';

class LiveDraftService {
  final FirebaseDatabase _database;

  Timer? _writeTimer;

  LiveDraftService({
    FirebaseDatabase? database,
  }) : _database = database ?? FirebaseDatabase.instance;

  // ============================================================
  // 草稿路径
  // ============================================================

  DatabaseReference _draftRef({
    required String chatId,
    required String userId,
  }) {
    return _database.ref(
      'chatDrafts/$chatId/$userId',
    );
  }

  // ============================================================
  // 断线清除
  // ============================================================

  Future<void> prepare({
    required String chatId,
    required String userId,
  }) async {
    final ref = _draftRef(
      chatId: chatId,
      userId: userId,
    );

    // 用户断网、关闭程序或程序崩溃时，
    // 自动删除这个用户在当前聊天室里的草稿。
    await ref.onDisconnect().remove();
  }

  // ============================================================
  // 更新自己的实时草稿
  // ============================================================

  void updateDraft({
    required String chatId,
    required String userId,
    required String text,
  }) {
    _writeTimer?.cancel();

    // 输入框已经清空，就立即删除草稿。
    if (text.trim().isEmpty) {
      unawaited(
        clearDraft(
          chatId: chatId,
          userId: userId,
        ),
      );

      return;
    }

    // 连续输入时，不要每按一次键立刻写数据库。
    // 停止输入 150ms 后再写入最新内容。
    _writeTimer = Timer(
      const Duration(milliseconds: 150),
      () async {
        try {
          final ref = _draftRef(
            chatId: chatId,
            userId: userId,
          );

          await ref.set({
            'text': text,
            'updatedAt': ServerValue.timestamp,
          });

          debugPrint(
            '草稿写入成功：chatDrafts/$chatId/$userId',
          );
        } catch (error) {
          debugPrint('草稿写入失败：$error');
        }
      },
    );
  }

  // ============================================================
  // 监听聊天室内其他成员的草稿
  // ============================================================

  Stream<List<LiveDraft>> watchChatDrafts({
    required String chatId,
    required String currentUserId,
  }) {
    return _database
        .ref('chatDrafts/$chatId')
        .onValue
        .map((event) {
      final rawValue = event.snapshot.value;

      if (rawValue is! Map) {
        return <LiveDraft>[];
      }

      final drafts = <LiveDraft>[];

      for (final entry in rawValue.entries) {
        final userId = entry.key.toString();

        // 不在实时预览框里显示自己的输入内容。
        // 这里只影响实时草稿框，不影响聊天消息显示自己的头像。
        if (userId == currentUserId) {
          continue;
        }

        final rawDraft = entry.value;

        if (rawDraft is! Map) {
          continue;
        }

        final draftData =
            Map<Object?, Object?>.from(rawDraft);

        final text =
            draftData['text']?.toString().trim() ?? '';

        final updatedAt = int.tryParse(
              draftData['updatedAt']?.toString() ?? '',
            ) ??
            0;

        if (text.isEmpty) {
          continue;
        }

        drafts.add(
          LiveDraft(
            userId: userId,
            text: text,
            updatedAt: updatedAt,
          ),
        );
      }

      // 最近更新输入内容的人排在最前面。
      drafts.sort(
        (first, second) {
          return second.updatedAt.compareTo(
            first.updatedAt,
          );
        },
      );

      return drafts;
    }).asBroadcastStream();
  }

  // ============================================================
  // 清除自己的草稿
  // ============================================================

  Future<void> clearDraft({
    required String chatId,
    required String userId,
  }) async {
    _writeTimer?.cancel();

    try {
      await _draftRef(
        chatId: chatId,
        userId: userId,
      ).remove();
    } catch (error) {
      debugPrint('草稿删除失败：$error');
    }
  }

  // ============================================================
  // 释放
  // ============================================================

  void dispose() {
    _writeTimer?.cancel();
  }
}