// lib/screens/friends_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/friend_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'friend_requests_screen.dart';
import 'user_profile_screen.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final friendService = FriendService();
  final chatService = ChatService();
  final currentUser = FirebaseAuth.instance.currentUser;

  // 引入一个简单的内存缓存，防止列表滚动时重复请求相同的用户信息
  final Map<String, Map<String, dynamic>> _userCache = {};

  Future<Map<String, dynamic>> _getUserInfo(String uid) async {
    if (_userCache.containsKey(uid)) {
      return _userCache[uid]!;
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text('我的好友', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.person_add_rounded, size: 26, color: Colors.black87),
                  tooltip: '好友申请',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FriendRequestsScreen(),
                      ),
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
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '${snapshot.data!.docs.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, height: 1.0),
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
      ),
      body: StreamBuilder<List<String>>(
        stream: friendService.myFriends(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.people_alt_outlined, size: 72, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 20),
                    const Text('暂无好友', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text('去发现用户页面添加一些新朋友吧', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            );
          }

          final friendUids = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: friendUids.length,
            separatorBuilder: (context, index) => Divider(height: 1, thickness: 0.5, indent: 76, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final friendUid = friendUids[index];

              return FutureBuilder<Map<String, dynamic>>(
                future: _getUserInfo(friendUid),
                builder: (context, userSnapshot) {
                  // 骨架屏占位：在未加载出数据时给出一个固定高度的预留行，防止高度塌陷带来的突兀闪烁
                  if (!userSnapshot.hasData) {
                    return _buildSkeletonListTile();
                  }

                  final userData = userSnapshot.data!;
                  final username = userData['username'] ?? '未知用户';
                  final email = userData['email'] ?? '';
                  final avatar = userData['avatar'] ?? '';

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(uid: friendUid),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          // 优雅的头像区
                          Hero(
                            tag: 'avatar_$friendUid',
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.blue.shade50,
                              backgroundImage: avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
                              child: avatar.isEmpty
                                  ? Text(
                                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor, fontSize: 16),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          
                          // 用户名及邮箱
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    email,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // 独立发消息动作按钮
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                            color: theme.primaryColor,
                            splashRadius: 24,
                            onPressed: () async {
                              final chatId = await chatService.getOrCreateChat(friendUid);
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    chatId: chatId,
                                    otherUserName: username,
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
      ),
    );
  }

  // 优雅的加载中占位骨架
  Widget _buildSkeletonListTile() {
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
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
            color: Colors.grey.shade200,
            onPressed: null,
          )
        ],
      ),
    );
  }
}