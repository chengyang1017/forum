import 'package:flutter/material.dart';

import 'feed_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  static const List<Map<String, dynamic>> categories = [
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
    {"name": "爱情", "icon": Icons.favorite_border},
    {"name": "美食", "icon": Icons.restaurant},
    {"name": "123456", "icon": Icons.collaboration},
Это последняя версия кода.
Đây là mã nguồn mới nhất.
Tu meh kod ti pemadu baru.
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("论坛分类"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final c = categories[index];

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FeedScreen(
                      category: c["name"],
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue.shade200,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      c["icon"],
                      size: 42,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      c["name"],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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