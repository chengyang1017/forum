import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/note_model.dart';
import '../services/note_service.dart';
import 'note_editor_screen.dart';

class AllNotesScreen extends StatefulWidget {
  const AllNotesScreen({
    super.key,
  });

  @override
  State<AllNotesScreen> createState() =>
      _AllNotesScreenState();
}

class _AllNotesScreenState
    extends State<AllNotesScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;
  final NoteService _noteService = NoteService();

  final Map<String, _SharedUser> _usersById = {};
  final Set<String> _loadingUserIds = {};

  String? _selectedUserId;
  bool _isCreating = false;

  String? get _currentUserId {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _loadUser(String userId) async {
    if (_usersById.containsKey(userId) ||
        _loadingUserIds.contains(userId)) {
      return;
    }

    _loadingUserIds.add(userId);

    try {
      final document = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!mounted) {
        return;
      }

      setState(() {
        _usersById[userId] =
            _SharedUser.fromDocument(document);
      });
    } catch (error) {
      debugPrint('加载共享用户失败：$userId，$error');
    } finally {
      _loadingUserIds.remove(userId);
    }
  }

void _ensureUsersLoaded(
  List<NoteModel> notes,
  String currentUserId,
) {
  final userIds = notes
      .expand(
        (note) => note.participantIds,
      )
      .where(
        (userId) =>
            userId.isNotEmpty &&
            userId != currentUserId,
      )
      .toSet();

  for (final userId in userIds) {
    unawaited(
      _loadUser(userId),
    );
  }
}

List<String> _sharedUserIds(
  List<NoteModel> notes,
  String currentUserId,
) {
  final userIds = notes
      .expand(
        (note) => note.participantIds,
      )
      .where(
        (userId) =>
            userId.isNotEmpty &&
            userId != currentUserId,
      )
      .toSet()
      .toList();

  userIds.sort(
    (firstId, secondId) {
      final firstName =
          _usersById[firstId]?.name ??
              '用户';

      final secondName =
          _usersById[secondId]?.name ??
              '用户';

      return firstName.compareTo(
        secondName,
      );
    },
  );

  return userIds;
}

  List<NoteModel> _filterNotes(
    List<NoteModel> notes,
  ) {
    final selectedUserId = _selectedUserId;

    if (selectedUserId == null) {
      return notes;
    }

    return notes
        .where((note) => note.includesUser(selectedUserId))
        .toList();
  }

Future<void> _createPrivateNote() async {
  final currentUserId =
      _currentUserId;

  if (currentUserId == null ||
      _isCreating) {
    return;
  }

  setState(() {
    _isCreating = true;
  });

  try {
    final noteId =
        await _noteService.createNote(
      ownerId: currentUserId,
    );

    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return NoteEditorScreen(
            noteId: noteId,
          );
        },
      ),
    );
  } catch (error) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '创建笔记失败：$error',
        ),
        backgroundColor:
            Colors.red,
      ),
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
        appBar: AppBar(
          title: const Text('我的笔记'),
        ),
        body: const Center(
          child: Text('请先登录'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: const Text('我的笔记'),
      ),
      body: StreamBuilder<List<NoteModel>>(
        stream: _noteService.watchNotesForUser(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '笔记加载失败',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final notes = snapshot.data ?? const <NoteModel>[];
          _ensureUsersLoaded(notes, currentUserId);

          final sharedUserIds = _sharedUserIds(
            notes,
            currentUserId,
          );
          final visibleNotes = _filterNotes(notes);

          if (_selectedUserId != null &&
              !sharedUserIds.contains(_selectedUserId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }

              setState(() {
                _selectedUserId = null;
              });
            });
          }

          return Column(
            children: [
              _buildUserFilters(sharedUserIds),
              Expanded(
                child: _buildNotesContent(
                  notes: visibleNotes,
                  currentUserId: currentUserId,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreating
            ? null
            : _createPrivateNote,
        icon: _isCreating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add),
        label: Text(
          _isCreating
              ? '正在创建'
              : '新建笔记',
        ),
      ),
    );
  }

  Widget _buildUserFilters(List<String> userIds) {
    if (userIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          itemCount: userIds.length + 1,
          separatorBuilder: (_, __) {
            return const SizedBox(width: 8);
          },
          itemBuilder: (context, index) {
            if (index == 0) {
              return ChoiceChip(
                label: const Text('全部'),
                selected: _selectedUserId == null,
                onSelected: (_) {
                  setState(() {
                    _selectedUserId = null;
                  });
                },
              );
            }

            final userId = userIds[index - 1];
            final user = _usersById[userId] ??
                _SharedUser(
                  id: userId,
                  name: '用户',
                );

            return ChoiceChip(
              avatar: _buildAvatar(
                user,
                radius: 13,
              ),
              label: Text(user.name),
              selected: _selectedUserId == userId,
              onSelected: (_) {
                setState(() {
                  _selectedUserId = userId;
                });
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotesContent({
    required List<NoteModel> notes,
    required String currentUserId,
  }) {
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
              _selectedUserId == null
                  ? '还没有共享笔记'
                  : '没有与这个用户共享的笔记',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '点击右下角新建',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        90,
      ),
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
  }

Widget _buildNoteCard({
  required NoteModel note,
  required String currentUserId,
}) {
  final title = note.title.trim();
  final content = note.content.trim();

  final canEdit =
      note.canEdit(currentUserId);

  final otherUserIds =
      note.participantIds
          .where(
            (userId) =>
                userId !=
                currentUserId,
          )
          .toList();

  final firstUser =
      otherUserIds.isEmpty
          ? null
          : _usersById[
              otherUserIds.first];

  final sharedLabel =
      _buildSharedLabel(
    otherUserIds,
  );

  return Material(
    color: Colors.white,
    borderRadius:
        BorderRadius.circular(16),
    child: InkWell(
      borderRadius:
          BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) {
              return NoteEditorScreen(
                noteId: note.id,
              );
            },
          ),
        );
      },
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            if (firstUser != null)
              _buildAvatar(
                firstUser,
                radius: 22,
              )
            else
              const CircleAvatar(
                radius: 22,
                child: Icon(
                  Icons.lock_outline,
                ),
              ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title.isEmpty
                              ? '无标题笔记'
                              : title,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Icon(
                        canEdit
                            ? Icons
                                .edit_outlined
                            : Icons
                                .lock_outline,
                        size: 17,
                        color: Colors.grey,
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    content.isEmpty
                        ? '暂无内容'
                        : content,
                    maxLines: 2,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: content.isEmpty
                          ? Colors.grey
                          : const Color(
                              0xFF666666,
                            ),
                    ),
                  ),

                  const SizedBox(height: 9),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sharedLabel,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                      Text(
                        _formatTime(
                          note.updatedAt,
                        ),
                        style:
                            const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _buildSharedLabel(
  List<String> userIds,
) {
  if (userIds.isEmpty) {
    return '仅自己可见';
  }

  final names = userIds
      .map(
        (userId) =>
            _usersById[userId]
                ?.name ??
            '用户',
      )
      .toList();

  if (names.length == 1) {
    return '与 ${names.first} 共享';
  }

  if (names.length == 2) {
    return '与 ${names.join('、')} 共享';
  }

  return '与 ${names.take(2).join('、')} 等 '
      '${names.length} 人共享';
}

  Widget _buildAvatar(
    _SharedUser user, {
    required double radius,
  }) {
    final avatarUrl = user.avatarUrl?.trim();

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE8E8E8),
      backgroundImage: avatarUrl != null &&
              avatarUrl.isNotEmpty
          ? NetworkImage(avatarUrl)
          : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? const Icon(
              Icons.person,
              color: Colors.grey,
            )
          : null,
    );
  }

  String _formatTime(DateTime dateTime) {
    if (dateTime.millisecondsSinceEpoch == 0) {
      return '';
    }

    final local = dateTime.toLocal();
    final now = DateTime.now();
    final isToday = local.year == now.year &&
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


class _SharedUser {
  final String id;
  final String name;
  final String username;
  final String? avatarUrl;

  const _SharedUser({
    required this.id,
    required this.name,
    this.username = '',
    this.avatarUrl,
  });

  factory _SharedUser.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final nickname = data['nickname']?.toString().trim();
    final displayName = data['displayName']?.toString().trim();
    final username = data['username']?.toString().trim() ?? '';
    final email = data['email']?.toString().trim();

    final name = nickname != null && nickname.isNotEmpty
        ? nickname
        : displayName != null && displayName.isNotEmpty
            ? displayName
            : username.isNotEmpty
                ? username
                : email != null && email.isNotEmpty
                    ? email
                    : '用户';

    final avatarUrl =
        data['avatarUrl']?.toString().trim() ??
            data['avatar']?.toString().trim() ??
            data['photoUrl']?.toString().trim();

    return _SharedUser(
      id: document.id,
      name: name,
      username: username,
      avatarUrl: avatarUrl,
    );
  }
}
