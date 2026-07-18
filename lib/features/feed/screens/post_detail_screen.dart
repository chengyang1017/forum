import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import 'comment_screen.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../providers/post_provider.dart' as postProv;
import '../../auth/providers/auth_provider.dart' as authProv;
import '../../../shared/widgets/user_name_display.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../data/models/post_model.dart';
import 'package:flutter/services.dart';
class PostDetailScreen extends StatefulWidget {
  final String postId;
  final PostModel post;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.post,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  // ✅ 所有字段改为带默认值，不再使用 late
  PostModel _post = PostModel(
    id: '',
    userId: '',
    content: '',
    category: '',
    languageCode: 'zh',
    imageUrls: [],
    likes: [],
    likeCount: 0,
    commentCount: 0,
  );

  bool _isLiked = false;
  List<String> _likes = [];
  List<String> _images = [];
  int _currentIndex = 0;
  bool _isUploadingImage = false;
  bool _isEditingImages = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // ✅ 安全初始化
    _post = widget.post;
    _currentUserId = context.read<authProv.AuthProvider>().user?.id;
    _likes = List<String>.from(_post.likes ?? []);
    _images = List<String>.from(_post.imageUrls ?? []);
    _isLiked = _currentUserId != null && _likes.contains(_currentUserId);
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return '刚刚';
    if (difference.inHours < 1) return '${difference.inMinutes} 分钟前';
    if (difference.inDays < 1) return '${difference.inHours} 小时前';
    if (difference.inDays < 7) return '${difference.inDays} 天前';
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // 编辑帖子
  // ============================================================
  Future<void> _editPost() async {
    final contentController = TextEditingController(text: _post.content ?? '');

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

    final newContent = contentController.text.trim();

    if (newContent.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('内容不能为空'), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    try {
      final postProvider = context.read<postProv.PostProvider>();
      final updatedPost = await postProvider.updatePost(
        widget.postId,
        content: newContent,
      );

      if (mounted) {
        setState(() {
          _post = updatedPost;
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

  // ============================================================
  // 点赞
  // ============================================================
  Future<void> _toggleLike() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likes.add(_currentUserId!);
      } else {
        _likes.remove(_currentUserId);
      }
    });

    try {
      final postProvider = context.read<postProv.PostProvider>();
      await postProvider.toggleLike(widget.postId, _currentUserId!);
    } catch (e) {
      setState(() {
        _isLiked = !_isLiked;
        if (_isLiked) {
          _likes.add(_currentUserId!);
        } else {
          _likes.remove(_currentUserId);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ============================================================
  // 分享
  // ============================================================
  // void _sharePost() {
  //   Share.share(_post.content ?? '');
  // }
  String get _postLink {
  return 'forum://post/${widget.postId}';
}

Future<void> _sharePost() async {
  final title = _post.title?.trim() ?? '';
  final content = _post.content?.trim() ?? '';

  final shareText = [
    if (title.isNotEmpty) title,
    if (content.isNotEmpty) content,
    _postLink,
  ].join('\n\n');

  await Share.share(
    shareText,
    subject: title.isNotEmpty ? title : '分享帖子',
  );
}

Future<void> _copyPostLink() async {
  await Clipboard.setData(
    ClipboardData(text: _postLink),
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('帖子链接已复制'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void _showShareOptions() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (bottomSheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(
                top: 12,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.ios_share_rounded,
              ),
              title: const Text('分享帖子'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _sharePost();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.link_rounded,
              ),
              title: const Text('复制链接'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _copyPostLink();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}

  // ============================================================
  // 删除帖子
  // ============================================================
  Future<void> _deletePost() async {
    if (_currentUserId != _post.userId) return;

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
      final postProvider = context.read<postProv.PostProvider>();
      await postProvider.deletePost(widget.postId);
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

  // ============================================================
  // 图片管理
  // ============================================================
  Future<void> _addImages() async {
    if (_images.length >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多只能添加 9 张图片 📸'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85, maxWidth: 1240);
    if (picked.isEmpty) return;

    setState(() => _isUploadingImage = true);

    try {
      final postProvider = context.read<postProv.PostProvider>();
      final newUrls = await postProvider.uploadImages(widget.postId, picked);
      
      if (mounted) {
        setState(() {
          _images.addAll(newUrls);
          if (_images.length > 9) _images = _images.sublist(0, 9);
          _isUploadingImage = false;
        });
        _post = _post.copyWith(imageUrls: _images);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
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
      final targetUrl = _images[index];
      setState(() {
        _images.removeAt(index);
        if (_currentIndex >= _images.length) _currentIndex = 0;
      });

      final postProvider = context.read<postProv.PostProvider>();
      await postProvider.removeImage(widget.postId, _images);
      await postProvider.deleteImageFromStorage(targetUrl);
      _post = _post.copyWith(imageUrls: _images);
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
      final img = _images.removeAt(oldIndex);
      _images.insert(newIndex, img);
      _currentIndex = newIndex;
    });
    try {
      final postProvider = context.read<postProv.PostProvider>();
      await postProvider.updateImages(widget.postId, _images);
      _post = _post.copyWith(imageUrls: _images);
    } catch (e) {
      setState(() {
        final img = _images.removeAt(newIndex);
        _images.insert(oldIndex, img);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('排序失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
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

  // ============================================================
  // 评论
  // ============================================================
  void _openComments() {
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
            Expanded(child: CommentScreen(postId: widget.postId)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 导航到用户主页
  // ============================================================
  void _navigateToProfile() {
    final uid = _post.userId;
    if (uid != null && uid.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfileScreen(uid: uid)),
      );
    }
  }

  // ============================================================
  // Build
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isOwner = _currentUserId == _post.userId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(isOwner),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_images.isNotEmpty)
                    _isEditingImages ? _buildEditableImageList() : _buildImageViewer(),
                  _buildContent(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar(bool isOwner) {
    return AppBar(
      title: const Text("详情", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1E293B),
      actions: [
        if (isOwner && _images.length > 1)
          IconButton(
            icon: Icon(_isEditingImages ? Icons.done_all_rounded : Icons.swap_vert_rounded, size: 22),
            color: _isEditingImages ? const Color(0xFF10B981) : const Color(0xFF64748B),
            tooltip: _isEditingImages ? '完成排序' : '重排图片',
            onPressed: () => setState(() => _isEditingImages = !_isEditingImages),
          ),
        if (isOwner)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF64748B)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'edit') _editPost();
              if (value == 'delete') _deletePost();
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
    );
  }

  // ============================================================
  // 小红书风格图片查看器
  // ============================================================
  void _openImagePreview(int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, animation, __) {
          return _XhsImagePreview(
            images: List<String>.unmodifiable(_images),
            initialIndex: initialIndex,
            postId: widget.postId,
          );
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildImageViewer() {
    return AspectRatio(
      // 小红书常见的竖图展示比例。
      aspectRatio: 3 / 4,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: _images.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openImagePreview(index),
                child: Hero(
                  tag: 'post-${widget.postId}-image-$index',
                  child: Material(
                    color: const Color(0xFFF2F2F2),
                    child: CachedNetworkImage(
                      imageUrl: _images[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 180),
                      placeholder: (_, __) {
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF2442),
                          ),
                        );
                      },
                      errorWidget: (_, __, ___) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            size: 48,
                            color: Color(0xFF9CA3AF),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          if (_images.length > 1)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.52),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${_currentIndex + 1}/${_images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          if (_images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_images.length, (index) {
                  final selected = index == _currentIndex;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: selected ? 13 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

          if (_isUploadingImage)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF2442),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // 可拖拽排序的图片编辑列表
  // ============================================================
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
                style: TextButton.styleFrom(foregroundColor: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _images.length,
            onReorder: _reorderImages,
            buildDefaultDragHandles: false,
            itemBuilder: (context, index) {
              return Container(
                key: ValueKey(_images[index]),
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
                          imageUrl: _images[index],
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

  // ============================================================
  // 帖子内容
  // ============================================================
  Widget _buildContent() {
    final title = _post.title?.trim() ?? '';
    final content = _post.content?.trim() ?? '';
    final userId = _post.userId ?? '';
    final category = _post.category ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (category.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "# $category",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600)
                ),
              ),
            ),
          if (title.isNotEmpty) ...[
  Text(
    title,
    style: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Color(0xFF0F172A),
      height: 1.3,
    ),
  ),
  const SizedBox(height: 14),
],
          Row(
            children: [
              if (userId.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: UserNameDisplay(uid: userId),
                ),
              const SizedBox(width: 12),
              const Icon(Icons.space_dashboard_outlined, size: 3, color: Colors.grey),
              const SizedBox(width: 12),
              Text(
                _formatTimestamp(_post.createdAt),
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)
              ),
            ],
          ),
          if (_post.updatedAt != null && _post.updatedAt != _post.createdAt) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.history_toggle_off_rounded, size: 13, color: Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text('修改于 ${_formatTimestamp(_post.updatedAt)}',
                    style: const TextStyle(color: Color(0xFFD97706), fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFF1F5F9), thickness: 1),
          ),
          Text(
            content.isNotEmpty ? content : '无内容',
            style: const TextStyle(fontSize: 16, height: 1.7, color: Color(0xFF334155), letterSpacing: 0.2)
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ============================================================
  // 底部操作栏
  // ============================================================
  Widget _buildBottomBar() {
    return Container(
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
                onTap: _toggleLike,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: _buildAction(
                    _isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                    _likes.isNotEmpty ? '${_likes.length} 赞同' : '赞同',
                    _isLiked,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _openComments,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: _buildAction(Icons.mode_comment_outlined, '评论', false),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _showShareOptions,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: _buildAction(Icons.ios_share_rounded, '分享', false),
                ),
              ),
            ],
          ),
        ),
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

class _XhsImagePreview extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String postId;

  const _XhsImagePreview({
    required this.images,
    required this.initialIndex,
    required this.postId,
  });

  @override
  State<_XhsImagePreview> createState() => _XhsImagePreviewState();
}

class _XhsImagePreviewState extends State<_XhsImagePreview> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => _showControls = !_showControls);
                },
                child: Center(
                  child: Hero(
                    tag: 'post-${widget.postId}-image-$index',
                    child: Material(
                      color: Colors.transparent,
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 5,
                        boundaryMargin: const EdgeInsets.all(80),
                        clipBehavior: Clip.none,
                        child: CachedNetworkImage(
                          imageUrl: widget.images[index],
                          width: MediaQuery.sizeOf(context).width,
                          height: MediaQuery.sizeOf(context).height,
                          fit: BoxFit.contain,
                          placeholder: (_, __) {
                            return const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            );
                          },
                          errorWidget: (_, __, ___) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                size: 64,
                                color: Colors.white38,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          IgnorePointer(
            ignoring: !_showControls,
            child: AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 14, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: '关闭',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_currentIndex + 1}/${widget.images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (widget.images.length > 1)
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(widget.images.length, (index) {
                          final selected = index == _currentIndex;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            width: selected ? 14 : 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.38),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

