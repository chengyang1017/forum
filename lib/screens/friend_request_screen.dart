import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/friend_service.dart';

class FriendRequestScreen extends StatelessWidget {
  FriendRequestScreen({super.key});

  final service = FriendService();

  @override
  Widget build(BuildContext context) {
    final uid = service.auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("好友申请")),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('friend_requests')
            .where('to', isEqualTo: uid)
            .where('status', isEqualTo: 'pending')
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("暂无申请"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i];

              return ListTile(
                title: Text("用户：${data['from']}"),

                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        service.acceptRequest(data['from']);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        service.rejectRequest(data['from']);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}