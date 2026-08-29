import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart' as authProv;
import '../providers/chat_provider.dart' as chatProv;
import '../../../social/presentation/providers/friend_provider.dart'
    as friendProv;
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ✅ 不再存储 currentUserId，改为从 AuthProvider 实时获取

  final Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ========== 用户信息缓存 ==========
  Future<Map<String, dynamic>> _getUserInfo(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid]!;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists && doc.data() != null) {
      _userCache[uid] = doc.data()!;
      return doc.data()!;
    }
    return {'username': '未知用户', 'email': '', 'avatar': ''};
  }

  String _formatTime(dynamic timestamp, AppLocalizations l10n) {
    if (timestamp == null) return '';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return '';
    }
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inHours < 1) return '${diff.inMinutes}${l10n.minutesAgo}';
    if (diff.inDays < 1) return '${diff.inHours}${l10n.hoursAgo}';
    if (diff.inDays < 7) return '${diff.inDays}${l10n.daysAgo}';
    return '${date.month}/${date.day}';
  }

  // ========== 显示用户资料 ==========
  void _showUserProfile(String uid, String displayName, String? avatar) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return FutureBuilder<Map<String, dynamic>>(
          future: _getUserInfo(uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: LoadingIndicator());
            }
            final data = snapshot.data!;
            final nickname = data['nickname'] ?? '';
            final username = data['username'] ?? '未知用户';
            final displayName2 = nickname.isNotEmpty ? nickname : username;
            final avatar2 = data['avatar'] ?? '';
            final bio = data['bio'] ?? '';
            final tags = List<String>.from(data['tags'] ?? []);

            return SingleChildScrollView(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 10),
                    UserAvatar(
                      imageUrl: avatar2,
                      displayName: displayName2,
                      radius: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayName2,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (nickname.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          bio,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Divider(height: 1, color: Colors.grey.shade200),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAction(
                            Icons.chat_bubble_outline_rounded,
                            l10n.send,
                            () async {
                              Navigator.pop(context);

                              final chatProvider = this.context
                                  .read<chatProv.ChatProvider>();

                              final chatId = await chatProvider.getOrCreateChat(
                                uid,
                              );

                              if (!mounted) {
                                return;
                              }

                              this.context.push(
                                AppRoutes.chatLocation(chatId: chatId),
                                extra: displayName2,
                              );
                            },
                          ),
                          _buildAction(
                            Icons.person_remove_outlined,
                            l10n.delete,
                            () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // ✅ 使用 watch 监听 AuthProvider，用户变化时自动重建
    final authProvider = context.watch<authProv.AuthProvider>();
    final currentUserId = authProvider.user?.id;

    // ✅ 如果未登录，显示提示页
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.messages), centerTitle: true),
        body: const Center(child: Text('请先登录')),
      );
    }

    // ✅ 用户已登录，加载数据（在 didChangeDependencies 中触发，但这里确保数据加载）
    // 利用 didChangeDependencies 加载数据（因为 currentUserId 变化时会触发重建）
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          l10n.messages,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.person_add_rounded,
                    size: 26,
                    color: Colors.black87,
                  ),
                  tooltip: l10n.reply,
                  onPressed: () {
                    context.push(AppRoutes.friendRequests);
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('friend_requests')
                      .where('to', isEqualTo: currentUserId)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox();
                    }
                    return Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '${snapshot.data!.docs.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: l10n.comment),
            Tab(text: l10n.reply),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatList(currentUserId),
          _buildFriendsList(currentUserId),
        ],
      ),
    );
  }

  // ========== 聊天列表（传入 currentUserId） ==========
  Widget _buildChatList(String currentUserId) {
    final chatProvider = context.watch<chatProv.ChatProvider>();
    final l10n = AppLocalizations.of(context)!;

    // 数据加载（由 Provider 内部处理，或在此触发）
    // 使用 didChangeDependencies 触发加载，但这里只负责展示

    // 使用 Stream 实时更新
    return StreamBuilder<QuerySnapshot>(
      stream: chatProvider.watchChats(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${l10n.loadFailed}：${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return EmptyState(
            icon: Icons.chat_bubble_outline,
            title: l10n.noPosts,
            subtitle: '还没有聊天，开始对话吧',
          );
        }

        final chats = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: chats.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, indent: 76, color: Colors.grey.shade100),
          itemBuilder: (context, index) {
            final chat = chats[index];
            final chatData = chat.data() as Map<String, dynamic>;
            final users = List<String>.from(chatData['users'] ?? []);
            final otherUserId = users.firstWhere(
              (id) => id != currentUserId,
              orElse: () => '',
            );

            final unreadCount = chatProvider.getUnreadCount(
              chatData,
              currentUserId,
            );
            final hasUnread = unreadCount > 0;

            return FutureBuilder<Map<String, dynamic>>(
              future: _getUserInfo(otherUserId),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return _buildSkeletonTile();
                }
                final userData = userSnapshot.data!;
                final name =
                    userData['username'] ?? userData['email'] ?? '未知用户';
                final avatar = userData['avatar'] ?? '';
                final lastMsg = chatData['lastMessage'];
                final hasMsg = lastMsg != null && lastMsg.toString().isNotEmpty;

                return InkWell(
                  onTap: () {
                    chatProvider.markAsRead(chat.id, currentUserId);

                    context.push(
                      AppRoutes.chatLocation(chatId: chat.id),
                      extra: name,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        UserAvatar(
                          imageUrl: avatar,
                          displayName: name,
                          radius: 24,
                          onTap: () {
                            if (otherUserId.isNotEmpty) {
                              _showUserProfile(otherUserId, name, avatar);
                            }
                          },
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                hasMsg ? lastMsg : l10n.noPosts,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: hasMsg
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(chatData['updatedAt'], l10n),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ========== 好友列表 ==========
  Widget _buildFriendsList(String currentUserId) {
    final friendProvider = context.watch<friendProv.FriendProvider>();

    return StreamBuilder<List<String>>(
      stream: friendProvider.watchFriends(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyState(
            icon: Icons.people_alt_outlined,
            title: '暂无好友',
            subtitle: '去发现页面添加好友吧',
          );
        }

        final friendUids = snapshot.data!;

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: friendUids.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, indent: 76, color: Colors.grey.shade100),
          itemBuilder: (context, index) {
            final friendUid = friendUids[index];

            return FutureBuilder<Map<String, dynamic>>(
              future: _getUserInfo(friendUid),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return _buildSkeletonTile();

                final userData = userSnapshot.data!;
                final name = userData['username'] ?? '未知用户';
                final email = userData['email'] ?? '';
                final avatar = userData['avatar'] ?? '';

                return InkWell(
                  onTap: () => _showUserProfile(friendUid, name, avatar),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        UserAvatar(
                          imageUrl: avatar,
                          displayName: name,
                          radius: 24,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 20,
                          ),
                          color: Theme.of(context).primaryColor,
                          splashRadius: 24,
                          onPressed: () async {
                            final chatProvider = this.context
                                .read<chatProv.ChatProvider>();

                            final chatId = await chatProvider.getOrCreateChat(
                              friendUid,
                            );

                            if (!mounted) {
                              return;
                            }

                            this.context.push(
                              AppRoutes.chatLocation(chatId: chatId),
                              extra: name,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSkeletonTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundColor: Colors.grey.shade100),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100, height: 14, color: Colors.grey.shade100),
                const SizedBox(height: 6),
                Container(width: 150, height: 11, color: Colors.grey.shade100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
