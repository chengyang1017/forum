// lib/screens/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/friend_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'friend_requests_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  final friendService = FriendService();
  final chatService = ChatService();
  final currentUser = FirebaseAuth.instance.currentUser;
  final Map<String, Map<String, dynamic>> _userCache = {};

  late TabController _tabController;

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

  Future<Map<String, dynamic>> _getUserInfo(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid]!;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      _userCache[uid] = doc.data()!;
      return doc.data()!;
    }
    return {'username': '未知用户', 'email': '', 'avatar': ''};
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return '';
    }
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${date.month}/${date.day}';
  }

  void _showUserProfile(String uid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FutureBuilder<Map<String, dynamic>>(
        future: _getUserInfo(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final nickname = data['nickname'] ?? '';
          final username = data['username'] ?? '未知用户';
          final displayName = nickname.isNotEmpty ? nickname : username;
          final avatar = data['avatar'] ?? '';
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
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.blue.shade50,
                    backgroundImage: avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
                    child: avatar.isEmpty
                        ? Text(
                            displayName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (nickname.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@$username',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    ),
                  ],
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                        children: tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Colors.grey.shade200),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildAction(Icons.chat_bubble_outline_rounded, '发消息', () async {
                          Navigator.pop(context);
                          final chatId = await chatService.getOrCreateChat(uid);
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(chatId: chatId, otherUserName: displayName),
                            ),
                          );
                        }),
                        _buildAction(Icons.person_remove_outlined, '删好友', () {
                          Navigator.pop(context);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
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
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text('消息',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.person_add_rounded,
                      size: 26, color: Colors.black87),
                  tooltip: '好友申请',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FriendRequestsScreen()),
                    );
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('friend_requests')
                      .where('to', isEqualTo: currentUser?.uid)
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
                            minWidth: 18, minHeight: 18),
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
                              height: 1.0),
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
          labelStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: '聊天'),
            Tab(text: '好友'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatList(theme),
          _buildFriendsList(theme),
        ],
      ),
    );
  }

  Widget _buildChatList(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('users', arrayContains: currentUser?.uid)
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('加载失败：${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('暂无聊天记录',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
              ],
            ),
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
              (id) => id != currentUser?.uid,
              orElse: () => '',
            );

            final unreadMap = chatData['unreadCount'] as Map<String, dynamic>? ?? {};
            final myUnread = (unreadMap[currentUser?.uid] ?? 0) as int;
            final hasUnread = myUnread > 0;

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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(chatId: chat.id, otherUserName: name),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (otherUserId.isNotEmpty) {
                              _showUserProfile(otherUserId);
                            }
                          },
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue.shade50,
                            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                            child: avatar.isEmpty
                                ? Text(name[0].toUpperCase(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: theme.primaryColor))
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text(
                                hasMsg ? lastMsg : '暂无消息',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: hasMsg ? Colors.grey[600] : Colors.grey[400],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              myUnread > 99 ? '99+' : '$myUnread',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(chatData['updatedAt']),
                              style: TextStyle(color: Colors.grey[400], fontSize: 11),
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

  Widget _buildFriendsList(ThemeData theme) {
    return StreamBuilder<List<String>>(
      stream: friendService.myFriends(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_alt_outlined,
                    size: 72, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('暂无好友',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
                const SizedBox(height: 6),
                Text('去发现页面添加好友吧',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ],
            ),
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
                  onTap: () => _showUserProfile(friendUid),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'avatar_$friendUid',
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue.shade50,
                            backgroundImage: avatar.isNotEmpty
                                ? CachedNetworkImageProvider(avatar)
                                : null,
                            child: avatar.isEmpty
                                ? Text(name[0].toUpperCase(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.primaryColor,
                                        fontSize: 16))
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              if (email.isNotEmpty)
                                Text(email,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 20),
                          color: theme.primaryColor,
                          splashRadius: 24,
                          onPressed: () async {
                            final chatId =
                                await chatService.getOrCreateChat(friendUid);
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  chatId: chatId,
                                  otherUserName: name,
                                ),
                              ),
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
                Container(
                    width: 100, height: 14, color: Colors.grey.shade100),
                const SizedBox(height: 6),
                Container(
                    width: 150, height: 11, color: Colors.grey.shade100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}