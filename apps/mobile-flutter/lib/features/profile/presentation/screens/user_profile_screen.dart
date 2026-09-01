import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart' as auth_cubit;
import '../../../chat/presentation/providers/chat_provider.dart' as chat_prov;
import '../../../post/domain/models/post_model.dart';
import '../../../post/domain/repositories/post_repository.dart';
import '../../../social/domain/models/friend_relationship_status.dart';
import '../../../social/domain/repositories/friend_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../widgets/profile_language_section.dart';
import '../widgets/profile_post_sliver_list.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final ProfileRepository _profileRepository;
  late final PostRepository _postRepository;
  late final FriendRepository _friendRepository;
  late final chat_prov.ChatProvider _chatProvider;

  String? _currentUserId;
  UserModel? _userProfile;
  bool _isLoading = true;
  FriendRelationshipStatus _relationshipStatus = FriendRelationshipStatus.none;

  @override
  void initState() {
    super.initState();
    _profileRepository = context.read<ProfileRepository>();
    _postRepository = context.read<PostRepository>();
    _friendRepository = context.read<FriendRepository>();
    _chatProvider = context.read<chat_prov.ChatProvider>();
    _currentUserId = context.read<auth_cubit.AuthCubit>().user?.id;
    _loadPageData();
  }

  Future<void> _loadPageData() async {
    await Future.wait([_loadProfile(), _loadRelationship()]);
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _profileRepository.getProfile(widget.uid);
      if (!mounted) return;
      setState(() {
        _userProfile = user;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Profile load failed: $error');
      if (!mounted) return;
      setState(() {
        _userProfile = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRelationship() async {
    if (_currentUserId == null || _currentUserId == widget.uid) return;

    try {
      final status = await _friendRepository.getRelationship(widget.uid);
      if (!mounted) return;
      setState(() => _relationshipStatus = status);
    } catch (error) {
      debugPrint('Friend relationship load failed: $error');
    }
  }

  Future<void> _sendFriendRequest() async {
    try {
      await _friendRepository.sendRequest(widget.uid);
      if (!mounted) return;
      setState(() {
        _relationshipStatus = FriendRelationshipStatus.requestSent;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已发送好友申请'), backgroundColor: Colors.green),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败: $error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _acceptFriendRequest(String displayName) async {
    try {
      await _friendRepository.acceptRequest(widget.uid);
      if (!mounted) return;
      setState(() {
        _relationshipStatus = FriendRelationshipStatus.friends;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已接受 $displayName 的好友申请'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _startChat(String displayName) async {
    try {
      final chatId = await _chatProvider.getOrCreateChat(widget.uid);
      if (!mounted) return;
      context.push(AppRoutes.chatLocation(chatId: chatId), extra: displayName);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('创建聊天失败: $error')));
    }
  }

  Stream<List<PostModel>> _watchUserPosts() {
    return _postRepository.watchUserPosts(widget.uid);
  }

  int _totalLikesOf(List<PostModel> posts) {
    return posts.fold<int>(0, (total, post) => total + post.likeCount);
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  bool _isDefaultBirthday(DateTime? date) {
    return date == null ||
        (date.year == 2000 && date.month == 1 && date.day == 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    final user = _userProfile;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('用户不存在'), centerTitle: true),
        body: const Center(
          child: Text('该用户不存在', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final username = user.username.isNotEmpty ? user.username : '未知用户';
    final nickname = user.nicknameText;
    final displayName = user.profileDisplayName.isNotEmpty
        ? user.profileDisplayName
        : username;
    final avatarUrl = user.avatarUrl;
    final bio = user.bioText;
    final tags = user.tagsList;
    final languages = user.languageList;
    final isMe = _currentUserId == widget.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: Text(
          nickname.isNotEmpty ? nickname : '@$username',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPageData,
        child: StreamBuilder<List<PostModel>>(
          stream: _watchUserPosts(),
          builder: (context, postSnapshot) {
            final posts = postSnapshot.data ?? const <PostModel>[];
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(
                    theme: theme,
                    user: user,
                    username: username,
                    nickname: nickname,
                    displayName: displayName,
                    avatarUrl: avatarUrl,
                    postCount: posts.length,
                    totalLikes: _totalLikesOf(posts),
                    isMe: isMe,
                  ),
                ),
                if (bio.isNotEmpty || tags.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildBioTagsSection(bio: bio, tags: tags),
                  ),
                if (languages.isNotEmpty)
                  SliverToBoxAdapter(
                    child: ProfileLanguageSection(
                      languages: languages,
                      l10n: l10n,
                      onTap: null,
                    ),
                  ),
                if (_currentUserId != null && !isMe)
                  SliverToBoxAdapter(
                    child: _buildSharedNotesEntry(displayName),
                  ),
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.dynamic_feed_rounded,
                          size: 20,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isMe ? '我的动态' : 'TA 的动态',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ProfilePostSliverList(snapshot: postSnapshot, l10n: l10n),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader({
    required ThemeData theme,
    required UserModel user,
    required String username,
    required String nickname,
    required String displayName,
    required String avatarUrl,
    required int postCount,
    required int totalLikes,
    required bool isMe,
  }) {
    final birthday = user.birthday;
    final showPublicAge =
        user.showAge && birthday != null && !_isDefaultBirthday(birthday);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildAvatar(avatarUrl, displayName, theme),
          const SizedBox(height: 16),
          Text(
            nickname.isNotEmpty ? nickname : '@$username',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (nickname.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
          if (showPublicAge) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cake, size: 14, color: Colors.pink[300]),
                const SizedBox(width: 4),
                Text(
                  '${_calculateAge(birthday)} 岁',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem('动态', postCount.toString()),
              Container(
                width: 1,
                height: 20,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 40),
              ),
              _buildStatItem('获赞', totalLikes.toString()),
            ],
          ),
          if (!isMe) ...[
            const SizedBox(height: 20),
            _buildActionButtons(displayName),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(String avatarUrl, String displayName, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        if (avatarUrl.isEmpty) return;
        showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                maxScale: 5,
                child: CachedNetworkImage(
                  imageUrl: avatarUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, _, _) =>
                      const Icon(Icons.person, size: 200, color: Colors.white),
                ),
              ),
            ),
          ),
        );
      },
      child: Hero(
        tag: 'avatar_${widget.uid}',
        child: CircleAvatar(
          radius: 46,
          backgroundColor: Colors.blue.shade50,
          backgroundImage: avatarUrl.isNotEmpty
              ? CachedNetworkImageProvider(avatarUrl)
              : null,
          child: avatarUrl.isEmpty
              ? Text(
                  displayName.isNotEmpty
                      ? displayName.substring(0, 1).toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildBioTagsSection({
    required String bio,
    required List<String> tags,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bio.isNotEmpty)
            Text(
              bio,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          if (bio.isNotEmpty && tags.isNotEmpty) const SizedBox(height: 16),
          if (tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map(
                    (tag) => Chip(
                      label: Text('# $tag'),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSharedNotesEntry(String displayName) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.note_alt_outlined),
        title: const Text('共同笔记'),
        subtitle: Text('查看与 $displayName 共享的笔记'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.push(
            AppRoutes.userNotesLocation(uid: widget.uid),
            extra: displayName,
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildActionButtons(String displayName) {
    switch (_relationshipStatus) {
      case FriendRelationshipStatus.friends:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _startChat(displayName),
                icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                label: const Text('发送消息'),
              ),
            ),
            const SizedBox(width: 12),
            const Chip(
              avatar: Icon(Icons.check_rounded, size: 16),
              label: Text('已是好友'),
            ),
          ],
        );
      case FriendRelationshipStatus.requestSent:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            '好友申请审核中...',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case FriendRelationshipStatus.requestReceived:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _acceptFriendRequest(displayName),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('通过好友申请'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        );
      case FriendRelationshipStatus.none:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _sendFriendRequest,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('添加好友'),
          ),
        );
    }
  }
}
