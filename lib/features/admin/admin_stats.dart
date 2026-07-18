import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStats extends StatelessWidget {
  const AdminStats({super.key});

  Future<int> getPostCount() async {
    final snap =
        await FirebaseFirestore.instance.collection('posts').get();
    return snap.size;
  }

  Future<int> getUserCount() async {
    final snap =
        await FirebaseFirestore.instance.collection('users').get();
    return snap.size;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        getPostCount(),
        getUserCount(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data![0];
        final users = snapshot.data![1];

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Posts: $posts"),
              Text("Users: $users"),
            ],
          ),
        );
      },
    );
  }
}