import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/friend_service.dart';

class UserListScreen extends StatelessWidget {
  UserListScreen({super.key});

  final friendService = FriendService();

  @override
  Widget build(BuildContext context) {
    final myUid = friendService.auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("用户列表")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs
              .where((u) => u.id != myUid)
              .toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, i) {
              final user = users[i];

              return ListTile(
                title: Text(user['username'] ?? "用户"),
                subtitle: Text(user['email'] ?? ""),

                trailing: ElevatedButton(
                  child: const Text("加好友"),
                  onPressed: () async {
                    await friendService.sendRequest(user.id);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("已发送好友申请")),
                    );
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