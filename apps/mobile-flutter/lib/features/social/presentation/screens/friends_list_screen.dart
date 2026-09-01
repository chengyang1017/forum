import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../chat/presentation/cubit/chat_cubit.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/repositories/friend_repository.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  late final FriendRepository _friendRepository;
  late final ProfileRepository _profileRepository;
  late final ChatCubit _chatCubit;

  final Map<String, Future<UserModel?>> _userCache = {};

  @override
  void initState() {
    super.initState();
    _friendRepository = context.read<FriendRepository>();
    _profileRepository = context.read<ProfileRepository>();
    _chatCubit = context.read<ChatCubit>();
  }

  Future<UserModel?> _getUser(String userId) {
    return _userCache.putIfAbsent(
      userId,
      () => _profileRepository.getProfile(userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          '我的好友',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.person_add_rounded,
                    size: 26,
                    color: Colors.black87,
                  ),
                  tooltip: '好友申请',
                  onPressed: () => context.push(AppRoutes.friendRequests),
                ),
                StreamBuilder<int>(
                  stream: _friendRepository.watchIncomingRequestCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    if (count <= 0) {
                      return const SizedBox();
                    }

                    return Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: _friendRepository.watchFriends(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }

          final friendIds = snapshot.data ?? const <String>[];
          if (friendIds.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.people_alt_outlined,
                        size: 72,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '暂无好友',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '去发现用户页面添加一些新朋友吧',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: friendIds.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 0.5,
              indent: 76,
              color: Colors.grey.shade100,
            ),
            itemBuilder: (context, index) {
              final friendId = friendIds[index];
              return FutureBuilder<UserModel?>(
                future: _getUser(friendId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildSkeletonListTile();
                  }

                  final user = userSnapshot.data;
                  final username = user?.username.isNotEmpty == true
                      ? user!.username
                      : '未知用户';
                  final displayName =
                      user?.profileDisplayName.isNotEmpty == true
                      ? user!.profileDisplayName
                      : username;
                  final email = user?.email ?? '';
                  final avatarUrl = user?.avatarUrl ?? '';

                  return InkWell(
                    onTap: () {
                      context.push(
                        AppRoutes.userProfileLocation(uid: friendId),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'avatar_$friendId',
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.blue.shade50,
                              backgroundImage: avatarUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(avatarUrl)
                                  : null,
                              child: avatarUrl.isEmpty
                                  ? Text(
                                      displayName.isNotEmpty
                                          ? displayName
                                                .substring(0, 1)
                                                .toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.primaryColor,
                                        fontSize: 16,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 20,
                            ),
                            color: theme.primaryColor,
                            splashRadius: 24,
                            onPressed: () async {
                              try {
                                final chatId = await _chatCubit
                                    .getOrCreateChat(friendId);
                                if (!mounted) return;
                                context.push(
                                  AppRoutes.chatLocation(chatId: chatId),
                                  extra: displayName,
                                );
                              } catch (error) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('创建聊天失败: $error')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSkeletonListTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundColor: Colors.grey.shade100),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100, height: 14, color: Colors.grey.shade100),
                const SizedBox(height: 6),
                Container(width: 150, height: 11, color: Colors.grey.shade100),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
            color: Colors.grey.shade200,
            onPressed: null,
          ),
        ],
      ),
    );
  }
}
