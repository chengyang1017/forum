import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_tab.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';
import 'discover_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int index = 0;
  final currentUser = FirebaseAuth.instance.currentUser;

  final pages = const [
    HomeTab(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DiscoverScreen()),
          );
        },
        child: const Icon(Icons.person_search),
      ),
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          int totalUnread = 0;
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final unreadMap = data['unreadCount'] as Map<String, dynamic>? ?? {};
              final count = (unreadMap[currentUser?.uid] ?? 0) as int;
              totalUnread += count;
            }
          }

          return BottomNavigationBar(
            currentIndex: index,
            onTap: (i) => setState(() => index = i),
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: "首页"),
              BottomNavigationBarItem(
                icon: totalUnread > 0
                    ? Badge(
                        label: Text(totalUnread > 99 ? '99+' : '$totalUnread'),
                        child: const Icon(Icons.chat),
                      )
                    : const Icon(Icons.chat),
                label: "消息",
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.person), label: "我的"),
            ],
          );
        },
      ),
    );
  }
}