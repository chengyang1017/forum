import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsers extends StatelessWidget {
  const AdminUsers({super.key});

  Future<void> banUser(String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'banned': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];

            return ListTile(
              title: Text(doc['email'] ?? ''),
              subtitle: Text(doc['role'] ?? 'user'),
              trailing: IconButton(
                icon: const Icon(Icons.block, color: Colors.red),
                onPressed: () => banUser(doc.id),
              ),
            );
          },
        );
      },
    );
  }
}