import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../post/domain/models/post_model.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../chat/data/services/chat_service.dart';
import '../../../social/data/services/friend_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart' as authProv;
import '../../../chat/presentation/screens/chat_screen.dart';
import '../widgets/profile_post_sliver_list.dart';
import '../../../notes/presentation/screens/user_notes_screen.dart';
import '../widgets/profile_language_section.dart';

class UserProfileScreen extends StatefulWidget {
  final String uid;

  const UserProfileScreen({super.key, required this.uid});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FriendService friendService = FriendService();
  final ChatService chatService = ChatService();

  String? _currentUserId;
  UserModel? _userProfile;

  bool isLoading = true;
  bool isFriend = false;
  String requestStatus = 'none';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadPageData();
  }

  void _loadCurrentUser() {
    final authProvider = context.read<authProv.AuthProvider>();
    final user = authProvider.user;
    if (user != null) {
      _currentUserId = user.id;
    }
  }

  Future<void> _loadPageData() async {
    await Future.wait([
      loadUserData(),
      checkFriendStatus(),
    ]);
  }

  Future<void> loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (!mounted) return;

      setState(() {
        if (doc.exists) {
          _userProfile = UserModel.fromJson({
            'uid': doc.id,
            ...?doc.data(),
          });
        }
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> checkFriendStatus() async {
    if (_currentUserId == null || _currentUserId == widget.uid) return;

    try {
      final friend = await friendService.isFriend(widget.uid);

      final sentRequests = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('from', isEqualTo: _currentUserId)
          .where('to', isEqualTo: widget.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      final receivedRequests = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('from', isEqualTo: widget.uid)
          .where('to', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (!mounted) return;

      setState(() {
        isFriend = friend;
        if (sentRequests.docs.isNotEmpty) {
          requestStatus = 'sent';
        } else if (receivedRequests.docs.isNotEmpty) {
          requestStatus = 'received';
        } else {
          requestStatus = 'none';
        }
      });
    } catch (_) {
      // 好友状态失败不影响个人主页显示。
    }
  }

  Future<void> sendFriendRequest() async {
    try {
      await friendService.sendRequest(widget.uid);

      if (!mounted) return;
      setState(() => requestStatus = 'sent');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已发送好友申请'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Stream<List<PostModel>> _watchUserPosts() {
    return FirebaseFirestore.instance
        .collection('posts')
        .where('uid', isEqualTo: widget.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PostModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  int _totalLikesOf(List<PostModel> posts) {
    return posts.fold<int>(0, (total, post) {
      return total + (post.likes?.length ?? post.likeCount);
    });
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

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

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    final userProfile = _userProfile;

    if (userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('用户不存在'), centerTitle: true),
        body: const Center(
          child: Text('该用户不存在', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final username = userProfile.username.isNotEmpty ? userProfile.username : '未知用户';
    final nickname = userProfile.nicknameText;
    final displayName = userProfile.profileDisplayName.isNotEmpty
        ? userProfile.profileDisplayName
        : username;
    final avatar = userProfile.avatarUrl;
    final bio = userProfile.bioText;
    final tags = userProfile.tagsList;
    final languages = userProfile.languageList;
    final birthday = userProfile.birthday;
    final showAge = userProfile.showAge;
    final isMe = _currentUserId == widget.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          nickname.isNotEmpty ? nickname : '@$username',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPageData,
        child: StreamBuilder<List<PostModel>>(
          stream: _watchUserPosts(),
          builder: (context, postSnapshot) {
            final posts = postSnapshot.data ?? <PostModel>[];
            final postCount = posts.length;
            final totalLikes = _totalLikesOf(posts);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(
                    theme: theme,
                    avatar: avatar,
                    username: username,
                    nickname: nickname,
                    displayName: displayName,
                    birthday: birthday,
                    showAge: showAge,
                    postCount: postCount,
                    totalLikes: totalLikes,
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

      // 其他用户主页只能查看
      onTap: null,
    ),
  ),
                  if (_currentUserId != null && !isMe)
  SliverToBoxAdapter(
    child: _buildSharedNotesEntry(
      displayName: displayName,
    ),
  ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.zero,
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
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ProfilePostSliverList(
                  snapshot: postSnapshot,
                  l10n: l10n,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader({
    required ThemeData theme,
    required String avatar,
    required String username,
    required String nickname,
    required String displayName,
    required DateTime? birthday,
    required bool showAge,
    required int postCount,
    required int totalLikes,
    required bool isMe,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildAvatar(avatar, displayName, theme),
          const SizedBox(height: 16),
          if (nickname.isNotEmpty) ...[
            Text(
              nickname,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ] else ...[
            Text(
              '@$username',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
          if (birthday != null && !_isDefaultBirthday(birthday)) ...[
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
                if (!showAge) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.lock, size: 12, color: Colors.grey[400]),
                ],
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

  Widget _buildAvatar(String avatar, String displayName, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        if (avatar.isEmpty) return;

        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                maxScale: 5.0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: avatar,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 200,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: Hero(
        tag: 'avatar_${widget.uid}',
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 46,
            backgroundColor: Colors.blue.shade50,
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildBioTagsSection({
    required String bio,
    required List<String> tags,
  }) {
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bio.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 20,
                  color: Colors.blue.shade300,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bio,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (bio.isNotEmpty && tags.isNotEmpty) const SizedBox(height: 16),
          if (tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '# $tag',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
  

  Widget _buildLanguageSection(List<Map<String, dynamic>> languages) {
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.translate_rounded, size: 18, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Text(
                '语言能力',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...languages.map((lang) {
            final level = lang['level'];
            final levelValue = level is num ? level.toDouble() : 70.0;
            final isNative = level == 'native';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      lang['name']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: isNative
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '母语 / Native',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: levelValue / 100,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade100,
                              color: Colors.green.shade400,
                            ),
                          ),
                  ),
                  if (!isNative)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        '${levelValue.toInt()}%',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSharedNotesEntry({
  required String displayName,
}) {
  final theme = Theme.of(context);

  return Container(
    margin: const EdgeInsets.only(
      top: 10,
    ),
    color: Colors.white,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      leading: CircleAvatar(
        backgroundColor:
            theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.note_alt_outlined,
          color: theme.colorScheme.primary,
        ),
      ),
      title: const Text(
        '共同笔记',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '查看与 $displayName 共享的笔记',
      ),
      trailing: const Icon(
        Icons.chevron_right,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) {
              return UserNotesScreen(
                otherUserId: widget.uid,
                otherUserName: displayName,
              );
            },
          ),
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
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(String displayName) {
    if (isFriend) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final chatId = await chatService.getOrCreateChat(widget.uid);

                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: chatId,
                      otherUserName: displayName,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_rounded, size: 18),
              label: const Text(
                '发送消息',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.check_rounded, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  '已是好友',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (requestStatus == 'sent') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time_filled_rounded,
              size: 18,
              color: Colors.orange.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              '好友申请审核中...',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (requestStatus == 'received') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            await friendService.acceptRequest(widget.uid);

            if (!mounted) return;
            setState(() => isFriend = true);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已接受 $displayName 的好友申请'),
                backgroundColor: Colors.green,
              ),
            );
          },
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text(
            '通过好友申请',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: sendFriendRequest,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
        label: const Text(
          '添加好友',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
