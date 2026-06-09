// lib/screens/post_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import 'comment_screen.dart';
import 'user_profile_screen.dart';
import '../widgets/user_name_display.dart';

class PostDetailScreen extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;

  const PostDetailScreen({
    super.key,
    required this.id,
    required this.data,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  // 使用本地状态接管数据，避免直接修改 widget.data 触发 unmodifiable 异常
  late String _title;
  late String _content;
  dynamic _editedAt;
  
  late bool isLiked;
  late List<String> likes;
  late List<String> images;
  int currentIndex = 0;
  bool isUploadingImage = false;
  bool isEditingImages = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    // 初始化本地文本状态
    _title = widget.data['title'] ?? '';
    _content = widget.data['content'] ?? '';
    _editedAt = widget.data['editedAt'];
    
    likes = List<String>.from(widget.data['likes'] ?? []);
    images = List<String>.from(widget.data['images'] ?? []);
    isLiked = uid != null && likes.contains(uid);
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return '';
    }
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return '刚刚';
    if (difference.inHours < 1) return '${difference.inMinutes} 分钟前';
    if (difference.inDays < 1) return '${difference.inHours} 小时前';
    if (difference.inDays < 7) return '${difference.inDays} 天前';
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
  }

  Future<void> _editPost() async {
    final titleController = TextEditingController(text: _title);
    final contentController = TextEditingController(text: _content);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('编辑帖子', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '标题',
                  hintText: '请输入标题...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFF43F5E), width: 1.5),
                  ),
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: InputDecoration(
                  labelText: '内容',
                  hintText: '分享新鲜事...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFF43F5E), width: 1.5),
                  ),
                ),
                maxLines: 6,
                maxLength: 5000,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final newTitle = titleController.text.trim();
    final newContent = contentController.text.trim();

    if (newTitle.isEmpty || newContent.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('标题和内容不能为空'), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('posts').doc(widget.id).update({
        'title': newTitle,
        'content': newContent,
        'editedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _title = newTitle;
          _content = newContent;
          _editedAt = DateTime.now();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('帖子已更新 ✨'), 
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> toggleLike() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likes.add(uid);
      } else {
        likes.remove(uid);
      }
    });

    await FirebaseFirestore.instance.collection('posts').doc(widget.id).update({
      'likes': isLiked ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid]),
    });
  }

  void sharePost() {
    Share.share("$_title\n\n$_content");
  }

  Future<void> deletePost() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != widget.data['uid']) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('删除帖子', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('确定要删除这个帖子吗？此操作不可撤销。', style: TextStyle(color: Color(0xFF64748B))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('确认删除', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('posts').doc(widget.id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('帖子已安全删除'), backgroundColor: Colors.black87, behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _addImages() async {
    if (images.length >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多只能添加 9 张图片 📸'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85, maxWidth: 1240);
    if (picked.isEmpty) return;

    setState(() => isUploadingImage = true);

    try {
      List<String> newUrls = [];
      for (final file in picked) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('posts/${widget.id}/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
        await ref.putFile(File(file.path));
        final url = await ref.getDownloadURL();
        newUrls.add(url);
      }

      if (mounted) {
        setState(() {
          images.addAll(newUrls);
          if (images.length > 9) images = images.sublist(0, 9);
          isUploadingImage = false;
        });
      }

      await FirebaseFirestore.instance.collection('posts').doc(widget.id).update({'images': images});

    } catch (e) {
      if (mounted) {
        setState(() => isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('图片上传失败: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _deleteImage(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('删除图片'),
        content: const Text('确定要移除这张图片吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除', style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final targetUrl = images[index];
      setState(() {
        images.removeAt(index);
        if (currentIndex >= images.length) currentIndex = 0;
      });
      
      await FirebaseFirestore.instance.collection('posts').doc(widget.id).update({'images': images});
      try { await FirebaseStorage.instance.refFromURL(targetUrl).delete(); } catch (_) {}
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步失败: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _reorderImages(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final img = images.removeAt(oldIndex);
      images.insert(newIndex, img);
      currentIndex = newIndex;
    });
    await FirebaseFirestore.instance.collection('posts').doc(widget.id).update({'images': images});
  }

  void _showImageOptions(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              title: const Text('删除这张图片', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w500)),
              onTap: () { Navigator.pop(context); _deleteImage(index); },
            ),
            ListTile(
              leading: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF2563EB)),
              title: const Text('追加更多图片'),
              onTap: () { Navigator.pop(context); _addImages(); },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void openComments() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(child: CommentScreen(postId: widget.id)),
        ],
      ),
    ),
  );
}

  // ========== 可拖拽排序的图片编辑列表 ==========
  Widget _buildEditableImageList() {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              const Text('长按右侧控制手柄拖动排序', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              const Spacer(),
              TextButton.icon(
                onPressed: _addImages,
                icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                label: const Text('添加图片', style: TextStyle(fontWeight: FontWeight.bold)),
                //style: TextButton.styleFrom(foregroundColor: const Color.fromARGB(255, 0, 0, 0)),
                style: TextButton.styleFrom(foregroundColor: Colors.black),

              ),
            ],
          ),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: images.length,
            onReorder: _reorderImages,
            buildDefaultDragHandles: false,
            itemBuilder: (context, index) {
              return Container(
                key: ValueKey(images[index]),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: images[index],
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
  '第 ${index + 1} 张',
  style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Color(0xFF94A3B8)),
                        onPressed: () => _showImageOptions(index),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Icon(Icons.menu_rounded, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ========== 正常高级感相册查看器 ==========
  Widget _buildImageViewer() {
    return Container(
      height: 340,
      color: const Color(0xFF0F172A),
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => currentIndex = i),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog.fullscreen(
                      backgroundColor: Colors.black,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: InteractiveViewer(
                              maxScale: 4.0,
                              child: CachedNetworkImage(
                                imageUrl: images[index],
                                fit: BoxFit.contain,
                                placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white24)),
                                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 64, color: Colors.white38),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 40,
                            left: 16,
                            child: CircleAvatar(
                              backgroundColor: Colors.black45,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Color(0xFFF43F5E))),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFE2E8F0),
                    child: const Center(child: Icon(Icons.broken_image_rounded, size: 48, color: Color(0xFF94A3B8))),
                  ),
                ),
              );
            },
          ),
          if (images.length > 1) ...[
            // 右下角精致数字标牌
            Positioned(
              bottom: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55), 
                  borderRadius: BorderRadius.circular(12),
                  //blur: null // 如需高斯模糊，可在外层加 BackdropFilter
                ),
                child: Text(
                  "${currentIndex + 1} / ${images.length}", 
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1),
                ),
              ),
            ),
            // 底部居中小圆点
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: currentIndex == i ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: currentIndex == i ? Colors.white : Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (isUploadingImage)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF43F5E)))),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isOwner = FirebaseAuth.instance.currentUser?.uid == data['uid'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("详情", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        actions: [
          if (isOwner && images.length > 1)
            IconButton(
              icon: Icon(isEditingImages ? Icons.done_all_rounded : Icons.swap_vert_rounded, size: 22),
              color: isEditingImages ? const Color(0xFF10B981) : const Color(0xFF64748B),
              tooltip: isEditingImages ? '完成排序' : '重排图片',
              onPressed: () => setState(() => isEditingImages = !isEditingImages),
            ),
          if (isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF64748B)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit') _editPost();
                if (value == 'delete') deletePost();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('编辑文本'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('删除帖子', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (images.isNotEmpty)
                    isEditingImages ? _buildEditableImageList() : _buildImageViewer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 分类标签
                        if (data['category'] != null && data['category'].toString().isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "# ${data['category']}", 
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600)
                              ),
                            ),
                          ),
                        // 标题
                        Text(
                          _title, 
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3)
                        ),
                        const SizedBox(height: 14),
                        // 用户信息及发布时间
                        Row(
                          children: [
                            if (data['uid'] != null) 
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: UserNameDisplay(uid: data['uid']),
                              ),
                            const SizedBox(width: 12),
                            const Icon(Icons.space_dashboard_outlined, size: 3, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              _formatTimestamp(data['timestamp']), 
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)
                            ),
                          ],
                        ),
                        // 已编辑小尾巴
                        if (_editedAt != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.history_toggle_off_rounded, size: 13, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 4),
                              Text('修改于 ${_formatTimestamp(_editedAt)}',
                                  style: const TextStyle(color: Color(0xFFD97706), fontSize: 12, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: Color(0xFFF1F5F9), thickness: 1),
                        ),
                        // 内容正文
                        Text(
                          _content, 
                          style: const TextStyle(fontSize: 16, height: 1.7, color: Color(0xFF334155), letterSpacing: 0.2)
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 底部极简优雅底座
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: toggleLike,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: _buildAction(
                          isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                          likes.isNotEmpty ? '${likes.length} 赞同' : '赞同',
                          isLiked,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: openComments,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: _buildAction(Icons.mode_comment_outlined, '评论', false),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: sharePost,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: _buildAction(Icons.ios_share_rounded, '分享', false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(IconData icon, String text, bool active) {
    final activeColor = const Color(0xFFF43F5E);
    final inactiveColor = const Color(0xFF64748B);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: active ? activeColor : inactiveColor),
        const SizedBox(width: 6),
        Text(
          text, 
          style: TextStyle(
            fontSize: 14, 
            color: active ? activeColor : inactiveColor, 
            fontWeight: active ? FontWeight.bold : FontWeight.w500
          )
        ),
      ],
    );
  }
}