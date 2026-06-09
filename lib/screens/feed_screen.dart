// lib/screens/feed_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import '../widgets/user_name_display.dart';

class FeedScreen extends StatelessWidget {
  final String category;

  const FeedScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: Colors.blueAccent, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePostScreen(category: category),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('category', isEqualTo: category)
            .orderBy('timestamp', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 3));
          }

          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (context, index) => Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return PostItemCard(postId: doc.id, data: data);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('暂无帖子', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class PostItemCard extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> data;

  const PostItemCard({
    super.key,
    required this.postId,
    required this.data,
  });

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return '';
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return '刚刚';
    if (difference.inHours < 1) return '${difference.inMinutes} 分钟前';
    if (difference.inDays < 1) return '${difference.inHours} 小时前';
    if (difference.inDays < 7) return '${difference.inDays} 天前';
    return '${dateTime.month}月${dateTime.day}日';
  }

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(data['images'] ?? []);
    final likes = List<String>.from(data['likes'] ?? []);
    final likeCount = likes.length;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(id: postId, data: data),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== 标题（大字体）==========
            Text(
              data['title'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF121212),
                height: 1.35,
              ),
            ),

            // ========== 内容摘要 ==========
            if (data['content'] != null && data['content'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                data['content'],
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF555555),
                  height: 1.55,
                ),
              ),
            ],

            // ========== 图片横排大图，可右滑 ==========
            if (images.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildImageRow(images),
            ],

            const SizedBox(height: 14),

// 第一行：左边昵称，右边时间
Row(
  children: [
    if (data['uid'] != null)
      Expanded(
        child: UserNameDisplay(uid: data['uid']),
      ),
    const SizedBox(width: 8),
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
    );
  }

  Widget _buildAction(IconData icon, String text, bool active) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: active ? const Color(0xFFF43F5E) : const Color(0xFF8590A6)),
      const SizedBox(width: 4),
      Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: active ? const Color(0xFFF43F5E) : const Color(0xFF8590A6),
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    ],
  );
}

  // ========== 横排大图，可右滑 ==========
  Widget _buildImageRow(List<String> images) {
    final screenWidth = MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first).size.width;
    final imageWidth = (screenWidth - 40) / 2.5; // 图片大约占屏幕的 2/5

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
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: images[index],
                    width: imageWidth,
                    height: imageWidth,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: imageWidth,
                      height: imageWidth,
                      color: const Color(0xFFF5F5F5),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: imageWidth,
                      height: imageWidth,
                      color: const Color(0xFFF5F5F5),
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 32),
                      ),
                    ),
                  ),
                  // 图片数量标记
                  if (index == images.length - 1 && images.length > 3)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          //borderRadius: BorderRadius.circular(0),
                        ),
                        child: Text(
                          '${images.length} 张',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}