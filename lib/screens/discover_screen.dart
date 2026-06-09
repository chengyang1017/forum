// lib/screens/discover_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/chat_service.dart';
import '../services/friend_service.dart';
import 'chat_screen.dart';
import 'user_profile_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final chatService = ChatService();
  final friendService = FriendService();
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("发现用户", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 3));
          }

          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('暂无其他用户', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final users = snapshot.data!.docs
              .where((doc) => doc.id != currentUser?.uid)
              .toList();

          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('暂无其他用户', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: users.length,
            separatorBuilder: (context, index) => Divider(height: 1, thickness: 1, color: Colors.grey.shade100, indent: 72),
            itemBuilder: (context, i) {
              final userData = users[i].data() as Map<String, dynamic>;
              final userId = users[i].id;
              final username = userData['username'] ?? '用户';
              final nickname = userData['nickname'] ?? '';
              final avatar = userData['avatar'] ?? '';

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserProfileScreen(uid: userId)),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue.shade50,
                        backgroundImage: avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
                        child: avatar.isEmpty
                            ? Text(
                                (nickname.isNotEmpty ? nickname : username)[0].toUpperCase(),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nickname.isNotEmpty ? nickname : '@$username',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF121212)),
                            ),
                            if (nickname.isNotEmpty)
                              Text(
                                '@$username',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 22),
                        color: Colors.blue,
                        tooltip: '开始聊天',
                        onPressed: () async {
                          try {
                            final chatId = await chatService.getOrCreateChat(userId);
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(chatId: chatId, otherUserName: username),
                              ),
                            );
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('创建聊天失败：$e')),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add_outlined, size: 22),
                        color: Colors.green,
                        tooltip: '加好友',
                        onPressed: () async {
                          try {
                            await friendService.sendRequest(userId);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('已向 ${nickname.isNotEmpty ? nickname : username} 发送好友申请'), backgroundColor: Colors.green),
                            );
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('发送失败：$e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}