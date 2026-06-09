// lib/screens/friend_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/friend_service.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final friendService = FriendService();
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<Map<String, String>> _getUserInfo(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    
    if (doc.exists) {
      final data = doc.data()!;
      return {
        'username': data['username'] ?? '未知用户',
        'avatar': data['avatar'] ?? '',
      };
    }
    return {'username': '未知用户', 'avatar': ''};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('好友申请'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ 查看发给我的申请
        stream: FirebaseFirestore.instance
            .collection('friend_requests')
            .where('to', isEqualTo: currentUser?.uid)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_disabled, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无好友申请', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final data = request.data() as Map<String, dynamic>;
              final fromUid = data['from'] as String;

              return FutureBuilder<Map<String, String>>(
                future: _getUserInfo(fromUid),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('加载中...'),
                    );
                  }

                  final userInfo = userSnapshot.data!;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // 头像
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: userInfo['avatar']!.isNotEmpty
                                ? NetworkImage(userInfo['avatar']!)
                                : null,
                            child: userInfo['avatar']!.isEmpty
                                ? Text(
                                    userInfo['username']![0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),

                          // 用户信息
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userInfo['username']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '请求添加你为好友',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 操作按钮
                          Column(
                            children: [
                              // ✅ 接受按钮
                              ElevatedButton(
                                onPressed: () async {
                                  await friendService.acceptRequest(fromUid);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('已接受 ${userInfo['username']} 的好友申请'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text('接受'),
                              ),
                              const SizedBox(height: 6),
                              // ❌ 拒绝按钮
                              OutlinedButton(
                                onPressed: () async {
                                  await friendService.rejectRequest(fromUid);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('已拒绝好友申请'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text('拒绝'),
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
      ),
    );
  }
}