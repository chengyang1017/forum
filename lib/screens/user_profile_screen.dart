// lib/screens/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/friend_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'post_detail_screen.dart';
import '../widgets/user_name_display.dart';

class UserProfileScreen extends StatefulWidget {
  final String uid;

  const UserProfileScreen({super.key, required this.uid});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final friendService = FriendService();
  final chatService = ChatService();
  final currentUser = FirebaseAuth.instance.currentUser;

  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isFriend = false;
  String requestStatus = 'none';

  @override
  void initState() {
    super.initState();
    loadUserData();
    checkFriendStatus();
  }

  Future<void> loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> checkFriendStatus() async {
    final friend = await friendService.isFriend(widget.uid);
    final requests = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('from', isEqualTo: currentUser?.uid)
        .where('to', isEqualTo: widget.uid)
        .where('status', isEqualTo: 'pending')
        .get();
    final receivedRequests = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('from', isEqualTo: widget.uid)
        .where('to', isEqualTo: currentUser?.uid)
        .where('status', isEqualTo: 'pending')
        .get();
    setState(() {
      isFriend = friend;
      if (requests.docs.isNotEmpty) {
        requestStatus = 'sent';
      } else if (receivedRequests.docs.isNotEmpty) {
        requestStatus = 'received';
      } else {
        requestStatus = 'none';
      }
    });
  }

  Future<void> sendFriendRequest() async {
    try {
      await friendService.sendRequest(widget.uid);
      setState(() => requestStatus = 'sent');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已发送好友申请'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is! Timestamp) return '';
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return '刚刚';
    if (difference.inHours < 1) return '${difference.inMinutes} 分钟前';
    if (difference.inDays < 1) return '${difference.inHours} 小时前';
    if (difference.inDays < 7) return '${difference.inDays} 天前';
    return '${dateTime.month}月${dateTime.day}日';
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) age--;
    return age;
  }

  bool _isDefaultBirthday(DateTime? date) {
    return date == null || (date.year == 2000 && date.month == 1 && date.day == 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 3)));
    }

    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('用户不存在'), centerTitle: true),
        body: const Center(child: Text('该用户不存在', style: TextStyle(color: Colors.grey))),
      );
    }

    final username = userData!['username'] ?? '未知用户';
    final nickname = userData!['nickname'] ?? '';
    final displayName = nickname.isNotEmpty ? nickname : username;
    final avatar = userData!['avatar'] ?? '';
    final bio = userData!['bio'] ?? '';
    final tags = List<String>.from(userData!['tags'] ?? []);
    final rawLangs = userData!['languages'] ?? [];

    DateTime? birthday;
    final bd = userData!['birthday'];
    if (bd is Timestamp) birthday = bd.toDate();
    final showAge = userData!['showAge'] ?? true;

    final List<Map<String, dynamic>> languages;
    if (rawLangs is List && rawLangs.isNotEmpty && rawLangs[0] is Map) {
      languages = List<Map<String, dynamic>>.from(rawLangs.map((e) => Map<String, dynamic>.from(e)));
    } else if (rawLangs is List && rawLangs.isNotEmpty && rawLangs[0] is String) {
      languages = rawLangs.map((e) => {'name': e.toString(), 'level': 70}).toList();
    } else {
      languages = [];
    }
    final isMe = currentUser?.uid == widget.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(nickname.isNotEmpty ? nickname : '@$username', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadUserData();
          await checkFriendStatus();
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('uid', isEqualTo: widget.uid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, postSnapshot) {
            int postCount = 0;
            int totalLikes = 0;
            if (postSnapshot.hasData) {
              postCount = postSnapshot.data!.docs.length;
              for (var doc in postSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final likes = List<String>.from(data['likes'] ?? []);
                totalLikes += likes.length;
              }
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildAvatar(avatar, displayName, theme),
                        const SizedBox(height: 16),
                        if (nickname.isNotEmpty) ...[
  Text(nickname, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
  const SizedBox(height: 4),
  Text('@$username', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
] else ...[
  Text('@$username', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
],
                        if (birthday != null && !_isDefaultBirthday(birthday)) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cake, size: 14, color: Colors.pink[300]),
                              const SizedBox(width: 4),
                              Text('${_calculateAge(birthday!)} 岁', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
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
                            Container(width: 1, height: 20, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 40)),
                            _buildStatItem('获赞', totalLikes.toString()),
                          ],
                        ),
                        if (!isMe) ...[
                          const SizedBox(height: 20),
                          _buildActionButtons(displayName),
                        ],
                      ],
                    ),
                  ),
                ),
                if (bio.isNotEmpty || tags.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
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
                                Icon(Icons.format_quote_rounded, size: 20, color: Colors.blue.shade300),
                                const SizedBox(width: 8),
                                Expanded(child: Text(bio, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5, fontStyle: FontStyle.italic))),
                              ],
                            ),
                          ],
                          if (bio.isNotEmpty && tags.isNotEmpty) const SizedBox(height: 16),
                          if (tags.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: tags.map((tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                                child: Text('# $tag', style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                              )).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (languages.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
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
                              Text('语言能力', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...languages.map((lang) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                SizedBox(width: 80, child: Text(lang['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87))),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: lang['level'] == 'native'
                                      ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)), child: Text('母语 / Native', style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.bold)))
                                      : ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (lang['level'] as num).toDouble() / 100, minHeight: 6, backgroundColor: Colors.grey.shade100, color: Colors.green.shade400)),
                                ),
                                if (lang['level'] != 'native') Padding(padding: const EdgeInsets.only(left: 10), child: Text('${lang['level']}%', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500))),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.zero,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Icon(Icons.dynamic_feed_rounded, size: 20, color: theme.primaryColor),
                        const SizedBox(width: 8),
                        Text(isMe ? '我的动态' : 'TA 的动态', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  ),
                ),
                _buildSliverPostList(postSnapshot),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatar(String avatar, String username, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        if (avatar.isNotEmpty) {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: InteractiveViewer(
                  maxScale: 5.0,
                  child: Center(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: CachedNetworkImage(imageUrl: avatar, fit: BoxFit.contain, placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)), errorWidget: (_, __, ___) => const Icon(Icons.person, size: 200, color: Colors.white)))),
                ),
              ),
            ),
          );
        }
      },
      child: Hero(
        tag: 'avatar_${widget.uid}',
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: CircleAvatar(
            radius: 46,
            backgroundColor: Colors.blue.shade50,
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty ? Text(username.isNotEmpty ? username[0].toUpperCase() : '?', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.primaryColor)) : null,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildActionButtons(String username) {
    if (isFriend) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final chatId = await chatService.getOrCreateChat(widget.uid);
                if (!mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, otherUserName: username)));
              },
              icon: const Icon(Icons.chat_bubble_rounded, size: 18),
              label: const Text('发送消息', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200, width: 1)),
            child: Row(children: [Icon(Icons.check_rounded, size: 16, color: Colors.grey.shade600), const SizedBox(width: 6), Text('已是好友', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 14))]),
          ),
        ],
      );
    } else if (requestStatus == 'sent') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.access_time_filled_rounded, size: 18, color: Colors.orange.shade600), const SizedBox(width: 8), Text('好友申请审核中...', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600))]),
      );
    } else if (requestStatus == 'received') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            await friendService.acceptRequest(widget.uid);
            setState(() => isFriend = true);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已接受 $username 的好友申请'), backgroundColor: Colors.green));
          },
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('通过好友申请', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: sendFriendRequest,
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: const Text('添加好友', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      );
    }
  }

  // ========== 帖子列表（知乎风格）==========
  Widget _buildSliverPostList(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return SliverToBoxAdapter(child: Container(color: Colors.white, padding: const EdgeInsets.all(32), child: const Center(child: CircularProgressIndicator(strokeWidth: 2))));
    }
    if (snapshot.hasError) {
      return SliverToBoxAdapter(child: Container(color: Colors.white, padding: const EdgeInsets.all(32), child: Center(child: Text("错误：${snapshot.error}", style: const TextStyle(color: Colors.red)))));
    }
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(color: Colors.white, padding: const EdgeInsets.symmetric(vertical: 64), child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.article_outlined, size: 44, color: Colors.grey), SizedBox(height: 12), Text("暂无动态帖子", style: TextStyle(color: Colors.grey, fontSize: 13))])),
      );
    }

    final docs = snapshot.data!.docs;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final doc = docs[index];
          final data = doc.data() as Map<String, dynamic>;
          final images = List<String>.from(data['images'] ?? []);
          final likes = List<String>.from(data['likes'] ?? []);
          final likeCount = likes.length;

          return Container(
            color: Colors.white,
            child: Column(
              children: [
                InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(id: doc.id, data: data))),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF121212), height: 1.35)),
                        if (data['content'] != null && data['content'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(data['content'], maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: Color(0xFF555555), height: 1.55)),
                        ],
                        if (images.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildImageRow(images),
                        ],
                        const SizedBox(height: 14),
Row(
  children: [
    if (data['uid'] != null)
    //   Expanded(
    //     child: UserNameDisplay(uid: data['uid']),
    //   ),
    // const SizedBox(width: 8),
    Text(
      _formatTimestamp(data['timestamp']),
      style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
    ),
  ],
),
const SizedBox(height: 6),

                      ],
                    ),
                  ),
                ),
                if (index < docs.length - 1) Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
              ],
            ),
          );
        },
        childCount: docs.length,
      ),
    );
  }

  Widget _buildAction(IconData icon, String text, bool active) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: active ? const Color(0xFFF43F5E) : const Color(0xFF8590A6)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 14, color: active ? const Color(0xFFF43F5E) : const Color(0xFF8590A6), fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }

  Widget _buildImageRow(List<String> images) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = (screenWidth - 40) / 2.5;

    return SizedBox(
      height: imageWidth,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: index < images.length - 1 ? 4 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: images[index],
                width: imageWidth,
                height: imageWidth,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: imageWidth, height: imageWidth, color: const Color(0xFFF5F5F5)),
                errorWidget: (_, __, ___) => Container(width: imageWidth, height: imageWidth, color: const Color(0xFFF5F5F5), child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 32))),
              ),
            ),
          );
        },
      ),
    );
  }
}