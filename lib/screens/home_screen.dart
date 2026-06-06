import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'feed_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Map<String, dynamic>> categories = const [
    {"name": "语言学习", "icon": Icons.language},
    {"name": "编程开发", "icon": Icons.code},
    {"name": "AI", "icon": Icons.smart_toy},
    {"name": "科技", "icon": Icons.computer},
    {"name": "游戏", "icon": Icons.sports_esports},
    {"name": "音乐", "icon": Icons.music_note},
    {"name": "影视", "icon": Icons.movie},
    {"name": "校园", "icon": Icons.school},
    {"name": "创业", "icon": Icons.business},
    {"name": "交友", "icon": Icons.people},
    {"name": "旅行", "icon": Icons.flight},
    {"name": "闲聊", "icon": Icons.chat},
  ];

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("论坛分类"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final c = categories[index];

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FeedScreen(category: c["name"]),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(c["icon"], color: Colors.blue, size: 40),
                    const SizedBox(height: 10),
                    Text(c["name"]),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}