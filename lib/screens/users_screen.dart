// screens/users_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ChatService();
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("用户列表")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          // 加载状态
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 错误处理
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载失败：${snapshot.error}'),
                ],
              ),
            );
          }

          // 无数据
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无其他用户', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 过滤掉当前用户
          final users = snapshot.data!.docs
              .where((doc) => doc.id != currentUser?.uid)
              .toList();

          if (users.isEmpty) {
            return const Center(child: Text('没有找到其他用户'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, i) {
              final userData = users[i].data() as Map<String, dynamic>;
              final userId = users[i].id;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      (userData['email'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  title: Text(
                    userData['username'] ?? userData['email'] ?? '未知用户',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(userData['email'] ?? ''),
                  trailing: const Icon(Icons.chat_bubble_outline),
                  onTap: () async {
                    try {
                      // ✅ 正确调用 getOrCreateChat
                      final chatId = await service.getOrCreateChat(userId);

                      if (!context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chatId,
                            otherUserName: userData['username'] ?? '用户',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('创建聊天失败：$e')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}