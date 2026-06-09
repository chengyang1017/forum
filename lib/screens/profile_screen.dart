// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/storage_service.dart';
import '../widgets/post_image_preview.dart';
import 'post_detail_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final _storageService = StorageService();

  String avatarUrl = '';
  String username = '';
  String nickname = '';
  String bio = '';
  List<String> tags = [];
  List<Map<String, dynamic>> languages = [];
  DateTime? birthday;
  bool showAge = true;
  bool loadingProfile = true;
  bool uploadingAvatar = false;

  final List<String> _presetTags = [
    'Flutter', 'Python', 'JavaScript', 'Java', 'C++', 'Go', 'Rust',
    '前端', '后端', '全栈', 'AI', '机器学习', '深度学习',
    'Android', 'iOS', 'Web', '小程序', '游戏开发',
    '摄影', '旅行', '美食', '音乐', '电影', '读书',
    '健身', '篮球', '足球', '跑步', '游泳',
    '学生', '上班族', '创业者', '自由职业',
  ];

  final List<String> _presetLanguages = [
    '中文', '英语', '日语', '韩语', '法语', '德语', '越南语', '维吾尔语', '哈萨克语', '克尔克孜语', '藏语', '蒙古语',
    '吉尔吉斯语', '乌兹别克语', '乌孜别克语', '西班牙语', '葡萄牙语', '俄语', '意大利语', '阿拉伯语',
    '粤语', '闽南语', '客家话', '上海话',
  ];

  String get displayName => nickname.isNotEmpty ? nickname : username;

  @override
  void initState() {
    super.initState();
    loadProfile();
    _fixOldPostsOnce(); // TODO: 修复完成后删除这行
  }

  // TODO: 修复完成后删除整个方法
  Future<void> _fixOldPostsOnce() async {
  try {
    final posts = await FirebaseFirestore.instance
        .collection('posts')
        .get();

    for (var doc in posts.docs) {
      final data = doc.data();
      final usernameField = data['username'];
      final nicknameField = data['nickname'];
      final uid = data['uid'];

      if ((usernameField == null || nicknameField == null) && uid != null) {
        // 从用户表获取 username 和 nickname
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final username = userData['username'] ?? '匿名用户';
          final nickname = userData['nickname'] ?? '';

          await doc.reference.update({
            'username': username,
            'nickname': nickname,
          });
          debugPrint('修复帖子: ${doc.id} -> username: $username');
        }
      }
    }
    debugPrint('所有老帖子修复完成');
  } catch (e) {
    debugPrint('修复老帖子失败: $e');
  }
}

  Future<void> loadProfile() async {
    try {
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          avatarUrl = data['avatar'] ?? '';
          username = data['username'] ?? '';
          nickname = data['nickname'] ?? '';
          bio = data['bio'] ?? '';
          tags = List<String>.from(data['tags'] ?? []);
          final bd = data['birthday'];
          if (bd is Timestamp) {
            birthday = bd.toDate();
          } else {
            birthday = null;
          }
          showAge = data['showAge'] ?? true;
          final rawLangs = data['languages'] ?? [];
          if (rawLangs is List && rawLangs.isNotEmpty) {
            try {
              languages = rawLangs.map((e) {
                if (e is Map) {
                  return Map<String, dynamic>.from(e);
                } else if (e is String) {
                  return {'name': e, 'level': 70};
                }
                return <String, dynamic>{};
              }).toList();
            } catch (e) {
              debugPrint('解析语言数据失败: $e');
              languages = [];
            }
          } else {
            languages = [];
          }
        });
      }
    } catch (e) {
      debugPrint('加载资料失败: $e');
    } finally {
      if (mounted) setState(() => loadingProfile = false);
    }
  }

  Future<void> _editTags() async {
    final selected = List<String>.from(tags);
    final customController = TextEditingController();

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModalState) => AnimatedPadding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            duration: const Duration(milliseconds: 150),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('编辑个性标签',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user!.uid)
                              .update({'tags': selected});
                          setState(() => tags = selected);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('标签更新成功'), backgroundColor: Colors.green),
                            );
                          }
                        },
                        child: const Text('完成', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (selected.isNotEmpty) ...[
                    Text('已选标签 (${selected.length}/10)',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selected.map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 13)),
                        backgroundColor: Colors.blue.shade50,
                        labelStyle: TextStyle(color: Colors.blue.shade800),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        deleteIcon: Icon(Icons.cancel, size: 16, color: Colors.blue.shade400),
                        onDeleted: () => setModalState(() => selected.remove(tag)),
                      )).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customController,
                          decoration: InputDecoration(
                            hintText: '输入自定义标签',
                            fillColor: Colors.grey.shade50,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            isDense: true,
                          ),
                          onSubmitted: (v) {
                            _addTag(v.trim(), selected, setModalState, ctx);
                            customController.clear();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          _addTag(customController.text.trim(), selected, setModalState, ctx);
                          customController.clear();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('添加'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('推荐标签', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _presetTags.map((tag) {
                          final isSelected = selected.contains(tag);
                          return GestureDetector(
                            onTap: () {
                              if (isSelected) {
                                setModalState(() => selected.remove(tag));
                              } else if (selected.length < 10) {
                                setModalState(() => selected.add(tag));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? Colors.blueAccent : Colors.grey.shade200,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected ? Colors.blue.shade800 : Colors.grey.shade700,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      customController.dispose();
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  bool _isDefaultBirthday(DateTime? date) {
    return date == null || (date.year == 2000 && date.month == 1 && date.day == 1);
  }

  Future<void> _editAge() async {
    bool tempShowAge = showAge;
    int tempYear = birthday?.year ?? 2000;
    int tempMonth = birthday?.month ?? 1;
    int tempDay = birthday?.day ?? 1;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('设置生日', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('选择你的出生日期', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPicker(tempYear == 2000 ? 'Y' : '$tempYear', 80, (i) => DateTime.now().year - i, (v) => setDialogState(() => tempYear = v)),
                  const SizedBox(width: 2),
                  const Text('年', style: TextStyle(fontSize: 14, color: Colors.black87)),
                  const SizedBox(width: 4),
                  _buildPicker(tempMonth == 1 ? 'M' : '$tempMonth', 12, (i) => i + 1, (v) => setDialogState(() => tempMonth = v)),
                  const SizedBox(width: 2),
                  const Text('月', style: TextStyle(fontSize: 14, color: Colors.black87)),
                  const SizedBox(width: 4),
                  _buildPicker(tempDay == 1 ? 'D' : '$tempDay', 31, (i) => i + 1, (v) => setDialogState(() => tempDay = v)),
                  const SizedBox(width: 2),
                  const Text('日', style: TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ),
              if (birthday != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton(
                    onPressed: () => setDialogState(() { tempYear = 2000; tempMonth = 1; tempDay = 1; }),
                    child: const Text('清除生日', style: TextStyle(color: Colors.red)),
                  ),
                ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.blue,
                title: const Text('公开年龄', style: TextStyle(fontSize: 14)),
                subtitle: const Text('关闭后仅自己可见', style: TextStyle(fontSize: 12)),
                value: tempShowAge,
                onChanged: (v) => setDialogState(() => tempShowAge = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: Colors.black87))),
            TextButton(
              onPressed: () {
                final date = DateTime(tempYear, tempMonth, tempDay);
                Navigator.pop(context, {
                  'birthday': _isDefaultBirthday(date)
                      ? FieldValue.delete() : Timestamp.fromDate(date),
                  'showAge': tempShowAge,
                });
              },
              child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    final newBirthday = result['birthday'] as Timestamp?;
    final newShowAge = result['showAge'] as bool;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'birthday': newBirthday ?? FieldValue.delete(),
        'showAge': newShowAge,
      });
      setState(() {
        birthday = newBirthday?.toDate();
        showAge = newShowAge;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('生日已更新'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新失败: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildPicker(String currentValue, int count, int Function(int) valueBuilder, Function(int) onChanged) {
    return PopupMenuButton<int>(
      offset: const Offset(0, 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 0.8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currentValue, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
          ],
        ),
      ),
      itemBuilder: (context) => List.generate(count, (i) {
        final val = valueBuilder(i);
        return PopupMenuItem(value: val, child: Text('$val', style: const TextStyle(fontSize: 14)));
      }),
      onSelected: onChanged,
    );
  }

  void _addTag(String tag, List<String> selected, Function setModalState, BuildContext ctx) {
    if (tag.isEmpty) return;
    if (selected.contains(tag)) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('该标签已经添加过了'), duration: Duration(seconds: 1)),
      );
      return;
    }
    if (selected.length >= 10) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('最多只能添加10个标签'), duration: Duration(seconds: 1)),
      );
      return;
    }
    setModalState(() => selected.add(tag));
  }

  Future<void> _editLanguages() async {
  final selected = List<Map<String, dynamic>>.from(languages);
  final nameController = TextEditingController();
  double tempLevel = 70;

  try {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.65,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('语言能力', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user!.uid)
                            .update({'languages': selected});
                        setState(() => languages = selected);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('语言已更新'), backgroundColor: Colors.green),
                          );
                        }
                      },
                      child: const Text('完成', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (selected.isNotEmpty)
                  Expanded(
                    flex: 3,
                    child: ListView(
                      shrinkWrap: true,
                      children: selected.asMap().entries.map((entry) {
                        final index = entry.key;
                        final lang = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    lang['name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    onTap: () => setModalState(() => selected.removeAt(index)),
                                    child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (lang['level'] == 'native')
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('母语',
                                        style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const Spacer(),
                                    InkWell(
                                      onTap: () => setModalState(() => selected[index]['level'] = 70),
                                      child: Text('改熟练度', style: TextStyle(fontSize: 11, color: Colors.blue[400])),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: (lang['level'] as num).toDouble(),
                                        min: 10,
                                        max: 100,
                                        divisions: 9,
                                        label: '${lang['level']}%',
                                        onChanged: (v) => setModalState(() => selected[index]['level'] = v.toInt()),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text('${lang['level']}%', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    InkWell(
                                      onTap: () => setModalState(() => selected[index]['level'] = 'native'),
                                      child: Text('母语', style: TextStyle(fontSize: 11, color: Colors.orange[600])),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                if (selected.isNotEmpty) const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: '语言名称',
                          hintStyle: TextStyle(fontSize: 13),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${tempLevel.toInt()}%', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        if (selected.any((l) => l['name'] == name)) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('已存在'), duration: Duration(seconds: 1)),
                          );
                          return;
                        }
                        setModalState(() {
                          selected.add({'name': name, 'level': tempLevel.toInt()});
                          tempLevel = 70;
                        });
                        nameController.clear();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Slider(
                  value: tempLevel,
                  min: 10,
                  max: 100,
                  divisions: 9,
                  label: '${tempLevel.toInt()}%',
                  onChanged: (v) => setModalState(() => tempLevel = v),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 6),
                const Text('快速选择', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _presetLanguages.map((name) {
                        final exists = selected.any((l) => l['name'] == name);
                        return GestureDetector(
                          onTap: exists
                              ? null
                              : () {
                                  setModalState(() => selected.add({'name': name, 'level': 70}));
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: exists ? Colors.green.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: exists ? Colors.green : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 12,
                                color: exists ? Colors.green.shade700 : Colors.grey[700],
                                fontWeight: exists ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  } finally {
    nameController.dispose();
  }
}

  Future<void> changeAvatar() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (image == null) return;
      setState(() => uploadingAvatar = true);
      if (avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) {
        await _storageService.deleteOldAvatar(avatarUrl);
      }
      final downloadUrl = await _storageService.uploadAvatar(File(image.path));
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'avatar': downloadUrl});
      setState(() {
        avatarUrl = downloadUrl;
        uploadingAvatar = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像更新成功'), backgroundColor: Colors.green),
        );
      }
    } on PlatformException catch (e) {
      setState(() => uploadingAvatar = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('需要相册权限: ${e.message}'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      setState(() => uploadingAvatar = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('头像更新失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> editNickname() async {
  final controller = TextEditingController(text: nickname);
  final newNickname = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('修改昵称'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: '新的昵称',
          hintText: '给自己起个好听的名字吧',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        maxLength: 20,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('保存')),
      ],
    ),
  );
  if (newNickname == null) return;
  try {
    // 更新用户表：如果清空了昵称就用 FieldValue.delete()
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'nickname': newNickname.isNotEmpty ? newNickname : FieldValue.delete(),
    });

    // 同步更新所有帖子
    final posts = await FirebaseFirestore.instance
        .collection('posts')
        .where('uid', isEqualTo: user!.uid)
        .get();
    for (var doc in posts.docs) {
      await doc.reference.update({
        'nickname': newNickname.isNotEmpty ? newNickname : FieldValue.delete(),
      });
    }

    setState(() => nickname = newNickname);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('昵称修改成功'), backgroundColor: Colors.green));
  } catch (e) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('修改失败: $e'), backgroundColor: Colors.red));
  }
}
  Future<void> editUsername() async {
  final controller = TextEditingController(text: username);
  final newUsername = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('修改用户名'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: '新的用户名',
          hintText: '用户名将作为你的唯一标识',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('保存')),
      ],
    ),
  );
  if (newUsername == null || newUsername.isEmpty) return;
  try {
    // 检查用户名是否已被使用
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: newUsername)
        .get();
    if (query.docs.isNotEmpty && query.docs.first.id != user!.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该用户名已被使用'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    
    // 更新用户表
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'username': newUsername});
    
    // 同步更新所有帖子
    final posts = await FirebaseFirestore.instance
        .collection('posts')
        .where('uid', isEqualTo: user!.uid)
        .get();
    for (var doc in posts.docs) {
      await doc.reference.update({'username': newUsername});
    }
    
    setState(() => username = newUsername);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('用户名修改成功'), backgroundColor: Colors.green));
  } catch (e) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('修改失败: $e'), backgroundColor: Colors.red));
  }
}

  Future<void> _editBio() async {
    final controller = TextEditingController(text: bio);
    final newBio = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑个人简介'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '介绍一下你自己...', border: OutlineInputBorder()),
          maxLines: 3,
          maxLength: 200,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('保存')),
        ],
      ),
    );
    if (newBio == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'bio': newBio});
      setState(() => bio = newBio);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('个人简介更新成功'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新失败: $e'), backgroundColor: Colors.red));
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime;
    if (timestamp is Timestamp) { dateTime = timestamp.toDate(); } else { return ''; }
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
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('个人主页'), centerTitle: true),
        body: const Center(child: Text('未登录', style: TextStyle(color: Colors.grey))),
      );
    }

    if (loadingProfile) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadProfile,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('uid', isEqualTo: user!.uid)
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
                        _buildAvatar(theme),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: editNickname,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  nickname.isNotEmpty ? nickname : '设置昵称',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: nickname.isNotEmpty ? Colors.black87 : Colors.grey.shade400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.edit_note_rounded, size: 20, color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: editUsername,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '@$username',
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.edit, size: 12, color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(user!.email ?? "", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),

                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _editAge,
                          child: _isDefaultBirthday(birthday)
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cake_outlined, size: 16, color: Colors.grey[400]),
                                    const SizedBox(width: 4),
                                    Text('设置生日', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                                    Icon(Icons.edit, size: 14, color: Colors.grey[400]),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cake, size: 16, color: Colors.pink[300]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_calculateAge(birthday!)} 岁',
                                      style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 4),
                                    if (!showAge) Icon(Icons.lock, size: 14, color: Colors.grey[400]),
                                    const SizedBox(width: 2),
                                    Icon(Icons.edit, size: 14, color: Colors.grey[400]),
                                  ],
                                ),
                        ),

                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatItem('动态', postCount.toString()),
                            Container(width: 1, height: 20, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 40)),
                            _buildStatItem('获赞', totalLikes.toString()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (bio.isNotEmpty || tags.isNotEmpty)
                  SliverToBoxAdapter(
                    child: GestureDetector(
                      onTap: _editBio,
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
                                  Expanded(
                                    child: Text(
                                      bio,
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit, size: 14, color: Colors.grey.shade400),
                                ],
                              ),
                            ],
                            if (bio.isNotEmpty && tags.isNotEmpty) const SizedBox(height: 16),
                            if (tags.isNotEmpty)
                              GestureDetector(
                                onTap: _editTags,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ...tags.map((tag) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '# $tag',
                                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                                      ),
                                    )),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(Icons.add, size: 14, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                            if (bio.isEmpty && tags.isEmpty) ...[
                              GestureDetector(
                                onTap: _editBio,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.format_quote_rounded, size: 18, color: Colors.grey[400]),
                                    const SizedBox(width: 6),
                                    Text('✨ 介绍一下自己...', style: TextStyle(color: Colors.grey[400], fontSize: 14, fontStyle: FontStyle.italic)),
                                    const SizedBox(width: 6),
                                    Icon(Icons.format_quote_rounded, size: 18, color: Colors.grey[400]),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _editTags,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('添加兴趣标签展示自我...', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                    const SizedBox(width: 4),
                                    Icon(Icons.add_circle_outline_rounded, size: 14, color: Colors.grey.shade400),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: _editLanguages,
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
                              Text(
                                '语言能力',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                              ),
                              const Spacer(),
                              if (languages.isEmpty)
                                Text('添加', style: TextStyle(fontSize: 12, color: Colors.green.shade600)),
                              Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
                            ],
                          ),
                          if (languages.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ...languages.map((lang) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      lang['name'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: lang['level'] == 'native'
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '母语 / Native',
                                              style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          )
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: (lang['level'] as num).toDouble() / 100,
                                              minHeight: 6,
                                              backgroundColor: Colors.grey.shade100,
                                              color: Colors.green.shade400,
                                            ),
                                          ),
                                  ),
                                  if (lang['level'] != 'native')
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Text(
                                        '${lang['level']}%',
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                ],
                              ),
                            )),
                          ],
                        ],
                      ),
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
                        const Text(
                          '我的动态',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
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

  Widget _buildAvatar(ThemeData theme) {
    return GestureDetector(
      onTap: changeAvatar,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
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
              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: uploadingAvatar
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : avatarUrl.isEmpty
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.primaryColor),
                        )
                      : null,
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: GestureDetector(
              onTap: changeAvatar,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
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
Widget _buildSliverPostList(AsyncSnapshot<QuerySnapshot> snapshot) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(32),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
  if (snapshot.hasError) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text("错误：${snapshot.error}", style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 44, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text("还没有发布过任何动态哦", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      ),
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

        return Container(
          color: Colors.white,
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PostDetailScreen(id: doc.id, data: data)),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF121212), height: 1.35),
                      ),
                      if (data['content'] != null && data['content'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          data['content'],
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, color: Color(0xFF555555), height: 1.55),
                        ),
                      ],
                      if (images.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildImageRow(images),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
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
              if (index < docs.length - 1)
                Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
            ],
          ),
        );
      },
      childCount: docs.length,
    ),
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
            borderRadius: BorderRadius.circular(3),
            child: CachedNetworkImage(
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
          ),
        );
      },
    ),
  );
}
  
}