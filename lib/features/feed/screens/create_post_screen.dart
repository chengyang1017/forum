import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../config/l10n/app_localizations.dart';

class CreatePostScreen extends StatefulWidget {
  final String category;
  final String languageCode;
  final String languageName;

  const CreatePostScreen({
    super.key,
    required this.category,
    //this.languageCode = 'zh', // 默认中文
    //this.languageName = '中文',
    required this.languageCode,
    required this.languageName,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final title = TextEditingController();
  final content = TextEditingController();

  List<File> images = [];

  bool isUploading = false;

  double progress = 0;

  static const List<String> _categoryIds = [
  'language_learning',
  'programming',
  'ai',
  'technology',
  'gaming',
  'music',
  'movies',
  'campus',
  'startup',
  'friends',
  'travel',
  'chat',
  'love',
  'food',
];

String _getCategoryName(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final index = _categoryIds.indexOf(widget.category);

  if (index == -1 || index >= l10n.categoryNames.length) {
    return widget.category;
  }

  return l10n.categoryNames[index];
}

  // 获取语言国旗
  String _getFlag(String code) {
    switch (code) {
      case 'zh':
        return '🇨🇳';
      case 'en':
        return '🇺🇸';
      case 'ja':
        return '🇯🇵';
      case 'ko':
        return '🇰🇷';
      case 'es':
        return '🇪🇸';
      case 'fr':
        return '🇫🇷';
      case 'de':
        return '🇩🇪';
      case 'pt':
        return '🇧🇷';
      case 'ru':
        return '🇷🇺';
      case 'ar':
        return '🇸🇦';
      case 'th':
        return '🇹🇭';
      case 'vi':
        return '🇻🇳';
      case 'id':
        return '🇮🇩';
      default:
        return '🌐';
    }
  }

  Future pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();

    if (picked.isEmpty) return;

    setState(() {
      images.addAll(picked.map((e) => File(e.path)));
      if (images.length > 9) {
        images = images.sublist(0, 9);
      }
    });
  }

  Future<List<String>> uploadImages(String postId) async {
    List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      final file = images[i];

      final ref = FirebaseStorage.instance
          .ref()
          .child('posts/$postId/$i.jpg');

      final uploadTask = ref.putFile(file);

      uploadTask.snapshotEvents.listen((event) {
        final fileProgress =
            event.bytesTransferred / event.totalBytes;

        setState(() {
          progress = (i + fileProgress) / images.length;
        });
      });

      await uploadTask;

      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  Future uploadPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (title.text.isEmpty || content.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("请填写标题和内容")),
      );
      return;
    }

    setState(() {
      isUploading = true;
      progress = 0;
    });

    try {
      // 获取用户信息
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();
      final username = userData?['username'] ?? '匿名用户';
      final nickname = userData?['nickname'] ?? '';

      final doc = FirebaseFirestore.instance.collection('posts').doc();

      final imageUrls = await uploadImages(doc.id);

      await doc.set({
        'title': title.text,
        'content': content.text,
        'category': widget.category,
        'languageCode': widget.languageCode, // 添加语言代码
        'languageName': widget.languageName, // 添加语言名称
        'uid': user.uid,
        'username': username,
        'nickname': nickname,
        'images': imageUrls,
        'likes': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("在${widget.languageName}频道发布成功"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      debugPrint("UPLOAD ERROR: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("上传失败: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
          progress = 0;
        });
      }
    }
  }

  // 删除图片时确认对话框
  void _confirmRemoveImage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("删除图片"),
        content: const Text("确定要删除这张图片吗？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () {
              setState(() => images.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text("删除", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    title.dispose();
    content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("发帖"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ========== 发布信息卡片 ==========
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    // 分类标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        //widget.category,
                        _getCategoryName(context),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 分隔符
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.blue.shade300,
                    ),
                    const SizedBox(width: 8),
                    // 语言标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getFlag(widget.languageCode),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.languageName,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // 提示信息
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "发布到此频道",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // ========== 标题输入 ==========
              TextField(
                controller: title,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: "标题",
                  hintText: "输入帖子标题...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  counterText: "",
                  suffixText: '${title.text.length}/100',
                  suffixStyle: TextStyle(
                    color: title.text.length > 90 ? Colors.red : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              
              const SizedBox(height: 16),
              
              // ========== 内容输入 ==========
              TextField(
                controller: content,
                maxLines: null,
                minLines: 5,
                maxLength: 5000,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: "内容",
                  hintText: "输入帖子内容...\n\n支持换行和表情符号 😊",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  alignLabelWithHint: true,
                  counterText: "",
                ),
                onChanged: (_) => setState(() {}),
              ),
              
              // 字符计数
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${content.text.length}/5000',
                  style: TextStyle(
                    color: content.text.length > 4500 ? Colors.red : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // ========== 图片选择区域 ==========
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.image, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "图片（可选）",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${images.length}/9",
                          style: TextStyle(
                            color: images.length >= 9 ? Colors.red : Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: isUploading 
                        ? null 
                        : images.length >= 9 
                          ? null 
                          : pickImages,
                      icon: const Icon(Icons.add_photo_alternate, size: 20),
                      label: Text(
                        images.isEmpty 
                          ? "选择图片" 
                          : images.length >= 9 
                            ? "已达上限" 
                            : "添加更多图片",
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // ========== 图片预览网格 ==========
              if (images.isNotEmpty) ...[
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: images.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          images[i],
                          fit: BoxFit.cover,
                        ),
                        // 序号标记
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        // 删除按钮
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _confirmRemoveImage(i),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              // ========== 上传进度 ==========
              if (isUploading) ...[
                const SizedBox(height: 20),
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "上传中 ${(progress * 100).toStringAsFixed(0)}%",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 24),
              
              // ========== 发布按钮 ==========
              ElevatedButton(
                onPressed: isUploading ? null : uploadPost,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isUploading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Icons.send_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isUploading ? "发布中..." : "发布帖子",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}