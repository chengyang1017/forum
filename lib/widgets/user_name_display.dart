import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/user_profile_screen.dart';

class UserNameDisplay extends StatelessWidget {
  final String uid;

  const UserNameDisplay({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('匿名用户', style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.w600));
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final nickname = data['nickname'] ?? '';
        final username = data['username'] ?? '匿名用户';
        final avatar = data['avatar'] ?? '';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UserProfileScreen(uid: uid)),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 8,
                backgroundColor: Colors.blue.shade50,
                backgroundImage: avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
                child: avatar.isEmpty
                    ? Text(
                        (nickname.isNotEmpty ? nickname : username)[0].toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Text(
                nickname.isNotEmpty ? nickname : '@$username',
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}