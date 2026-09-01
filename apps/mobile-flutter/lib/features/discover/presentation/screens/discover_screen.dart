import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart' as auth_cubit;
import '../../domain/models/discover_user.dart';
import '../providers/discover_provider.dart' as discover_prov;

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final authProvider = context.read<auth_cubit.AuthCubit>();
    final user = authProvider.user;
    if (user != null) {
      _currentUserId = user.id;
    }
  }

  Future<void> _startChat(DiscoverUser user) async {
    try {
      final discoverProvider = context.read<discover_prov.DiscoverProvider>();
      final chatId = await discoverProvider.getOrCreateChat(user.id);
      if (!mounted) return;
      context.push(
        AppRoutes.chatLocation(chatId: chatId),
        extra: user.displayName,
      );
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.startChat}失败：$error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendFriendRequest(DiscoverUser user) async {
    try {
      final discoverProvider = context.read<discover_prov.DiscoverProvider>();
      await discoverProvider.sendFriendRequest(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已向 ${user.displayName} 发送好友请求'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送好友请求失败：$error'), backgroundColor: Colors.red),
      );
    }
  }

  void _navigateToProfile(String userId) {
    context.push(AppRoutes.userProfileLocation(uid: userId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.discover), centerTitle: true),
        body: const Center(child: Text('请先登录')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.discover,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        ),
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    final discoverProvider = context.watch<discover_prov.DiscoverProvider>();
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<DiscoverUser>>(
      stream: discoverProvider.watchAllUsers(_currentUserId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              '${l10n.loadFailed}：${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final users = snapshot.data ?? const <DiscoverUser>[];
        if (users.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            title: l10n.noOtherUsers,
            subtitle: '还没有其他用户，邀请朋友加入吧',
          );
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          itemCount: users.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade100,
            indent: 72,
          ),
          itemBuilder: (context, index) {
            final user = users[index];

            return InkWell(
              onTap: () => _navigateToProfile(user.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      imageUrl: user.avatarUrl,
                      displayName: user.displayName,
                      radius: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(0xFF121212),
                            ),
                          ),
                          if (user.nickname.isNotEmpty)
                            Text(
                              '@${user.username}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 22,
                      ),
                      color: Colors.blue,
                      tooltip: l10n.startChat,
                      onPressed: () => _startChat(user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add_outlined, size: 22),
                      color: Colors.green,
                      tooltip: l10n.addFriend,
                      onPressed: () => _sendFriendRequest(user),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
