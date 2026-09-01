import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../post/domain/models/post_model.dart';
import '../../../post/domain/repositories/post_repository.dart';
import '../../application/ports/profile_media_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../providers/profile_provider.dart';
import '../widgets/birthday_editor_dialog.dart';
import '../widgets/language_editor_sheet.dart';
import '../widgets/profile_bio_tags_section.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_language_section.dart';
import '../../../post/presentation/widgets/post_item_card.dart';
import '../widgets/tag_editor_sheet.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  late final String? _userId;
  late final String _userEmail;
  late final ProfileProvider _profileProvider;

  final List<String> _presetTags = [
    'Flutter',
    'Python',
    'JavaScript',
    'Java',
    'C++',
    'Go',
    'Rust',
    '前端',
    '后端',
    '全栈',
    'AI',
    '机器学习',
    '深度学习',
    'Android',
    'iOS',
    'Web',
    '小程序',
    '游戏开发',
    '摄影',
    '旅行',
    '美食',
    '音乐',
    '电影',
    '读书',
    '健身',
    '篮球',
    '足球',
    '跑步',
    '游泳',
    '学生',
    '上班族',
    '创业者',
    '自由职业',
  ];

  // final List<String> _presetLanguageCodes = [
  //   'zh',
  //   'en',
  //   'ja',
  //   'ko',
  //   'fr',
  //   'de',
  //   'vi',
  //   'ug',
  //   'kk',
  //   'es',
  //   'pt',
  //   'ru',
  //   'it',
  //   'ar',
  //   'th',
  //   'hi',
  //   'tr',
  //   'nl',
  //   'pl',
  //   'uk',
  //   'sv',
  //   'no',
  //   'da',
  //   'fi',
  //   'cs',
  //   'ro',
  //   'hu',
  //   'el',
  //   'he',
  //   'bn',
  //   'ur',
  //   'fa',
  //   'tl',
  //   'sw',
  //   'my',
  //   'km',
  //   'lo',
  //   'mn',
  //   'ne',
  //   'si',
  //   'am',
  //   'ky',
  //   'uz',
  //   'az',
  //   'ka',
  //   'hy',
  //   'sq',
  //   'hr',
  //   'sr',
  //   'bg',
  //   'sk',
  //   'sl',
  //   'lt',
  //   'lv',
  //   'et',
  // ];

  @override
  void initState() {
    super.initState();
    final authUser = context.read<AuthCubit>().user;
    _userId = authUser?.id;
    _userEmail = authUser?.email ?? '';

    _profileProvider = ProfileProvider(
      postRepository: context.read<PostRepository>(),
      profileRepository: context.read<ProfileRepository>(),
      mediaRepository: context.read<ProfileMediaRepository>(),
    );
    loadProfile();
  }

  @override
  void dispose() {
    _profileProvider.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    if (_userId == null) return;
    await _profileProvider.loadProfile(_userId);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _editTags() async {
    if (_userId == null) return;

    final result = await showTagEditorSheet(
      context: context,
      selectedTags: _profileProvider.tags,
      presetTags: _presetTags,
    );

    if (result == null) return;

    try {
      await _profileProvider.updateTags(_userId, result);
      _showSuccess('标签更新成功');
    } catch (e) {
      _showError('更新失败: $e');
    }
  }

  Future<void> _editLanguages() async {
    if (_userId == null) return;

    final result = await showLanguageEditorSheet(
      context: context,
      selectedLanguages: _profileProvider.languages,
      //presetLanguageCodes: _presetLanguageCodes,
    );

    if (result == null) return;

    try {
      await _profileProvider.updateLanguages(_userId, result);
      _showSuccess('语言已更新');
    } catch (e) {
      _showError('更新失败: $e');
    }
  }

  Future<void> _editAge() async {
    if (_userId == null) return;

    final result = await showBirthdayEditorDialog(
      context: context,
      birthday: _profileProvider.birthday,
      showAge: _profileProvider.showAge,
    );

    if (result == null) return;

    try {
      await _profileProvider.updateBirthday(
        _userId,
        result.birthday,
        result.showAge,
      );
      _showSuccess('生日已更新');
    } catch (e) {
      _showError('更新失败: $e');
    }
  }

  Future<void> changeAvatar() async {
    try {
      if (_userId == null) return;

      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image == null) return;

      await _profileProvider.updateAvatar(_userId, File(image.path));
      _showSuccess('头像更新成功');
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('需要相册权限: ${e.message}'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      _showError('头像更新失败: $e');
    }
  }

  Future<void> editNickname() async {
    if (_userId == null) return;

    final controller = TextEditingController(text: _profileProvider.nickname);
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    //controller.dispose(); //这里太早

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (newNickname == null) return;

    try {
      await _profileProvider.updateNickname(_userId, newNickname);
      _showSuccess('昵称修改成功');
    } catch (e) {
      _showError('修改失败: $e');
    }
  }

  Future<void> editUsername() async {
    if (_userId == null) return;

    final controller = TextEditingController(text: _profileProvider.username);
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    //controller.dispose();//这里太早

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (newUsername == null || newUsername.isEmpty) return;

    try {
      await _profileProvider.updateUsername(_userId, newUsername);
      _showSuccess('用户名修改成功');
    } catch (e) {
      _showError('修改失败: $e');
    }
  }

  Future<void> _editBio() async {
    if (_userId == null) return;

    final controller = TextEditingController(text: _profileProvider.bio);
    final newBio = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑个人简介'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '介绍一下你自己...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          maxLength: 200,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    //controller.dispose();//这里太早

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (newBio == null) return;

    try {
      await _profileProvider.updateBio(_userId, newBio);
      _showSuccess('个人简介更新成功');
    } catch (e) {
      _showError('更新失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProfileProvider>.value(
      value: _profileProvider,
      child: Consumer<ProfileProvider>(
        builder: (context, profile, _) => _buildBody(context, profile),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProfileProvider profile) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // 用户未登录。
    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profile), centerTitle: true),
        body: Center(
          child: Text(
            l10n.notLoggedIn,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // 正在加载个人资料。
    if (profile.loadingProfile) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // ============================================================
      // 顶部导航栏
      // ============================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,

        title: Text(
          profile.displayName,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () {
              context.push(AppRoutes.settings);
            },
          ),
        ],
      ),

      // ============================================================
      // 页面内容
      // ============================================================
      body: RefreshIndicator(
        onRefresh: loadProfile,

        child: StreamBuilder<List<PostModel>>(
          stream: profile.watchUserPosts(_userId),

          builder: (context, postSnapshot) {
            final posts = postSnapshot.data ?? const <PostModel>[];

            final postCount = posts.length;
            final totalLikes = profile.totalLikesOf(posts);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),

              slivers: [
                // ====================================================
                // 个人资料头部
                // ====================================================
                SliverToBoxAdapter(
                  child: ProfileHeader(
                    profile: profile,
                    email: _userEmail,
                    postCount: postCount,
                    totalLikes: totalLikes,
                    l10n: l10n,
                    onAvatarTap: changeAvatar,
                    onNicknameTap: editNickname,
                    onUsernameTap: editUsername,
                    onBirthdayTap: _editAge,
                  ),
                ),

                // ====================================================
                // 简介和兴趣标签
                // ====================================================
                SliverToBoxAdapter(
                  child: ProfileBioTagsSection(
                    bio: profile.bio,
                    tags: profile.tags,
                    l10n: l10n,
                    onEditBio: _editBio,
                    onEditTags: _editTags,
                  ),
                ),

                // ====================================================
                // 语言能力
                // ====================================================
                SliverToBoxAdapter(
                  child: ProfileLanguageSection(
                    languages: profile.languages,
                    l10n: l10n,
                    onTap: _editLanguages,
                  ),
                ),

                //笔记
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    color: Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.note_alt_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: const Text(
                        '我的笔记',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text('查看和管理所有共享笔记'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push(AppRoutes.allNotes);
                      },
                    ),
                  ),
                ),

                // 我的收藏
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    color: Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        child: Icon(
                          Icons.bookmark_outline_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      title: const Text(
                        '我的收藏',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text('查看收藏的帖子'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push(AppRoutes.bookmarkedPosts);
                      },
                    ),
                  ),
                ),

                // ====================================================
                // 我的帖子标题
                // ====================================================
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
                          l10n.myPosts,
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

                // ====================================================
                // 帖子加载中
                // ====================================================
                if (postSnapshot.connectionState == ConnectionState.waiting)
                  const SliverToBoxAdapter(
                    child: ColoredBox(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    ),
                  )
                // ====================================================
                // 帖子加载失败
                // ====================================================
                else if (postSnapshot.hasError)
                  SliverToBoxAdapter(
                    child: ColoredBox(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 45,
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 44,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '帖子加载失败',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${postSnapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                // ====================================================
                // 没有帖子
                // ====================================================
                else if (posts.isEmpty)
                  const SliverToBoxAdapter(
                    child: ColoredBox(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 50),
                        child: Column(
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              '暂无帖子',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                // ====================================================
                // 使用 PostItemCard 显示帖子
                // ====================================================
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // 奇数位置显示分隔线。
                        if (index.isOdd) {
                          return Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey.shade100,
                          );
                        }

                        // 因为中间加入了分隔线，
                        // 所以真实帖子索引需要除以 2。
                        final postIndex = index ~/ 2;
                        final post = posts[postIndex];

                        return ColoredBox(
                          color: Colors.white,
                          child: PostItemCard(
                            post: post,

                            // 个人主页不重复显示作者信息。
                            showUserInfo: false,

                            // 显示语言频道标签。
                            showLanguageBadge: true,
                          ),
                        );
                      },

                      // 例如有三条帖子：
                      // 帖子、分隔线、帖子、分隔线、帖子
                      // 一共五个子元素。
                      childCount: posts.length * 2 - 1,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
