import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../discover/domain/models/discover_user.dart';
import '../../../discover/domain/repositories/discover_repository.dart';
import '../../../social/domain/repositories/follow_repository.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.select<AuthCubit, String?>(
      (cubit) => cubit.user?.id,
    );

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('用户列表')),
        body: const Center(child: Text('请先登录')),
      );
    }

    final discoverRepository = context.read<DiscoverRepository>();
    final chatRepository = context.read<ChatRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('用户列表')),
      body: StreamBuilder<List<DiscoverUser>>(
        stream: discoverRepository.watchAllUsers(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _UsersErrorState(error: snapshot.error);
          }

          final users = snapshot.data ?? const <DiscoverUser>[];

          if (users.isEmpty) {
            return const _UsersEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: _UserAvatar(user: user),
                  title: Text(
                    user.displayName.isEmpty ? '未知用户' : user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: user.username.isEmpty
                      ? null
                      : Text('@${user.username}'),
                  trailing: _FollowButton(userId: user.id),
                  onTap: () => _openChat(
                    context: context,
                    chatRepository: chatRepository,
                    user: user,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openChat({
    required BuildContext context,
    required ChatRepository chatRepository,
    required DiscoverUser user,
  }) async {
    try {
      final chatId = await chatRepository.getOrCreateChat(user.id);

      if (!context.mounted) {
        return;
      }

      context.push(
        AppRoutes.chatLocation(chatId: chatId),
        extra: user.displayName.isEmpty ? user.username : user.displayName,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('创建聊天失败：$error')));
    }
  }
}

class _FollowButton extends StatefulWidget {
  const _FollowButton({required this.userId});

  final String userId;

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<FollowRepository>();

    return StreamBuilder<bool>(
      stream: repository.watchIsFollowing(widget.userId),
      initialData: false,
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;

        return FilledButton.tonalIcon(
          onPressed: _isBusy
              ? null
              : () => _toggleFollow(
                  repository: repository,
                  isFollowing: isFollowing,
                ),
          icon: _isBusy
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isFollowing
                      ? Icons.person_rounded
                      : Icons.person_add_alt_1_rounded,
                  size: 17,
                ),
          label: Text(isFollowing ? '已关注' : '关注'),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
      },
    );
  }

  Future<void> _toggleFollow({
    required FollowRepository repository,
    required bool isFollowing,
  }) async {
    setState(() => _isBusy = true);

    try {
      if (isFollowing) {
        await repository.unfollow(widget.userId);
      } else {
        await repository.follow(widget.userId);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('关注操作失败：$error')));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final DiscoverUser user;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl.trim();

    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(avatarUrl));
    }

    final name = user.displayName.trim();
    final fallback = name.isNotEmpty ? name : user.username.trim();
    final initial = fallback.isEmpty
        ? 'U'
        : fallback.characters.first.toUpperCase();

    return CircleAvatar(child: Text(initial));
  }
}

class _UsersEmptyState extends StatelessWidget {
  const _UsersEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无其他用户', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _UsersErrorState extends StatelessWidget {
  const _UsersErrorState({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('加载失败：$error'),
        ],
      ),
    );
  }
}
