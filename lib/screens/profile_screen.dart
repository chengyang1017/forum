import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'post_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  String avatarUrl =
      "https://cdn-icons-png.flaticon.com/512/149/149071.png";

  bool isLoadingAvatar = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // ================= 加载头像 =================
  Future<void> loadProfile() async {
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['avatar'] != null) {
          setState(() {
            avatarUrl = data['avatar'];
          });
        }
      }
    } catch (e) {
      debugPrint("loadProfile error: $e");
    }
  }

  // ================= 更换头像（本地版） =================
  Future<void> changeAvatar() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    setState(() {
      avatarUrl = image.path;
      isLoadingAvatar = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({
        'avatar': image.path,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("avatar upload error: $e");
    } finally {
      setState(() => isLoadingAvatar = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("未登录")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("个人主页")),

      body: Column(
        children: [
          const SizedBox(height: 20),

          // ================= 头像 =================
          GestureDetector(
            onTap: changeAvatar,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: avatarUrl.startsWith("/")
                      ? FileImage(File(avatarUrl))
                      : NetworkImage(avatarUrl) as ImageProvider,
                ),

                if (isLoadingAvatar)
                  const CircularProgressIndicator(),
              ],
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "点击头像修改",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 10),

          Text(
            user!.email ?? "",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              "我的帖子",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ================= 帖子列表 =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('uid', isEqualTo: user!.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),

              builder: (context, snapshot) {

                // 🚨 错误处理（关键！你之前没有）
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "加载失败:\n${snapshot.error}",
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // ⏳ loading
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text("没有数据"));
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("暂无帖子"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data =
                        doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(data['title'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(data['category'] ?? ''),

                            const SizedBox(height: 5),

                            // 显示是否有图片
                            if ((data['images'] ?? [])
                                .isNotEmpty)
                              const Text(
                                "📷 有图片",
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PostDetailScreen(
                                id: doc.id,
                                data: data,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}