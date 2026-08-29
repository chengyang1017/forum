import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

import '../../domain/models/note_model.dart';
import '../../data/services/note_service.dart';

class UserNotesScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const UserNotesScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<UserNotesScreen> createState() => _UserNotesScreenState();
}

class _UserNotesScreenState extends State<UserNotesScreen> {
  final NoteService _noteService = NoteService();

  bool _isCreating = false;

  String? get _currentUserId {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _createNote() async {
    final currentUserId = _currentUserId;

    if (currentUserId == null || _isCreating) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final noteId = await _noteService.createNote(
        ownerId: currentUserId,
        sharedUserIds: [widget.otherUserId],
      );

      if (!mounted) {
        return;
      }

      await context.push<void>(AppRoutes.noteEditorLocation(noteId: noteId));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建笔记失败：$error'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _currentUserId;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('共享笔记')),
        body: const Center(child: Text('请先登录')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: Text(
          '${widget.otherUserName} · 笔记',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: StreamBuilder<List<NoteModel>>(
        stream: _noteService.watchNotesWithUser(
          currentUserId: currentUserId,
          otherUserId: widget.otherUserId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '加载笔记失败：${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final notes = snapshot.data ?? const <NoteModel>[];

          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: 56,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '还没有与 ${widget.otherUserName} 共享的笔记',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '点击右下角新建',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: notes.length,
            separatorBuilder: (_, __) {
              return const SizedBox(height: 10);
            },
            itemBuilder: (context, index) {
              return _buildNoteCard(
                note: notes[index],
                currentUserId: currentUserId,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreating ? null : _createNote,
        icon: _isCreating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: Text(_isCreating ? '正在创建' : '新建笔记'),
      ),
    );
  }

  Widget _buildNoteCard({
    required NoteModel note,
    required String currentUserId,
  }) {
    final title = note.title.trim();
    final content = note.content.trim();
    final canEdit = note.canEdit(currentUserId);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push(AppRoutes.noteEditorLocation(noteId: note.id));
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title.isEmpty ? '无标题笔记' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    canEdit ? Icons.edit_outlined : Icons.lock_outline,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                content.isEmpty ? '暂无内容' : content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: content.isEmpty
                      ? Colors.grey
                      : const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.ownerId == currentUserId
                          ? '由你创建'
                          : '由 ${widget.otherUserName} 创建',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  Text(
                    _formatTime(note.updatedAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    if (dateTime.millisecondsSinceEpoch == 0) {
      return '';
    }

    final local = dateTime.toLocal();
    final now = DateTime.now();
    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    if (isToday) {
      return '$hour:$minute';
    }

    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');

    if (local.year == now.year) {
      return '$month-$day';
    }

    return '${local.year}-$month-$day';
  }
}
