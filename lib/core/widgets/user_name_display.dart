import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../features/profile/presentation/screens/user_profile_screen.dart';

class UserNameDisplay extends StatelessWidget {
  final String uid;

  const UserNameDisplay({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final normalizedUid = uid.trim();

    if (normalizedUid.isEmpty) {
      return const _AnonymousUserDisplay();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(normalizedUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _AnonymousUserDisplay();
        }

        if (!snapshot.hasData) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          );
        }

        final document = snapshot.data;

        if (document == null || !document.exists) {
          return const _AnonymousUserDisplay();
        }

        final data = document.data();

        if (data == null) {
          return const _AnonymousUserDisplay();
        }

        final nickname = data['nickname']?.toString().trim() ?? '';

        final username = data['username']?.toString().trim() ?? '';

        final avatar = data['avatar']?.toString().trim() ?? '';

        final displayName = nickname.isNotEmpty
            ? nickname
            : username.isNotEmpty
            ? '@$username'
            : '匿名用户';

        final avatarLetter = nickname.isNotEmpty
            ? nickname.characters.first.toUpperCase()
            : username.isNotEmpty
            ? username.characters.first.toUpperCase()
            : '匿';

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => UserProfileScreen(uid: normalizedUid),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: ClipOval(
                  child: avatar.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: avatar,
                          width: 16,
                          height: 16,
                          fit: BoxFit.cover,
                          placeholder: (_, __) {
                            return Container(
                              width: 16,
                              height: 16,
                              color: Colors.blue.shade50,
                            );
                          },
                          errorWidget: (_, __, ___) {
                            return _AvatarFallback(letter: avatarLetter);
                          },
                        )
                      : _AvatarFallback(letter: avatarLetter),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String letter;

  const _AvatarFallback({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      color: Colors.blue.shade50,
      alignment: Alignment.center,
      child: Text(
        letter,
        maxLines: 1,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }
}

class _AnonymousUserDisplay extends StatelessWidget {
  const _AnonymousUserDisplay();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircleAvatar(
            radius: 8,
            backgroundColor: Color(0xFFE3F2FD),
            child: Icon(Icons.person, size: 11, color: Colors.blue),
          ),
        ),
        SizedBox(width: 6),
        Text(
          '匿名用户',
          style: TextStyle(
            color: Colors.blueAccent,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
