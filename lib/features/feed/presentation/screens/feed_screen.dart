import 'package:flutter/material.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';
import 'package:provider/provider.dart';

import '../providers/feed_provider.dart' as feedProv;
import '../../../auth/presentation/providers/auth_provider.dart' as authProv;
import '../../../post/presentation/screens/create_post_screen.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../post/presentation/widgets/post_item_card.dart';
import '../../../post/domain/models/post_model.dart';

class FeedScreen extends StatelessWidget {
  final String category;
  final String languageCode;
  final String languageName;

  const FeedScreen({
    super.key,
    required this.category,
    //this.languageCode = 'zh',
    //this.languageName = '中文',
    required this.languageCode,
    required this.languageName,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<authProv.AuthProvider>();
    final currentUserId = authProvider.user?.id;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: StreamBuilder<List<PostModel>>(
        stream: context.read<feedProv.FeedProvider>().watchPosts(
          category: category,
          languageCode: languageCode,
          currentUserId: currentUserId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          }

          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<feedProv.FeedProvider>().refreshPosts(
                category: category,
                languageCode: languageCode,
                currentUserId: currentUserId,
              );
            },
            child: ListView.separated(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              itemCount: posts.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostItemCard(
                  post: post,
                  showUserInfo: true,
                  showLanguageBadge: true,
                );
              },
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            category,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              fontSize: 18,
            ),
          ),
          Text(
            _getLanguageDisplay(),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
                  builder: (_) => CreatePostScreen(
                    category: category,
                    languageCode: languageCode,
                    languageName: languageName,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          const Text(
            '加载失败',
            style: TextStyle(
              fontSize: 16,
              color: Colors.redAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$error',
            style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.article_outlined,
      title: '暂无$languageName帖子',
      subtitle: '成为第一个在$category分类下\n发布$languageName帖子的人吧',
      onAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreatePostScreen(
              category: category,
              languageCode: languageCode,
              languageName: languageName,
            ),
          ),
        );
      },
      actionLabel: '发布$languageName帖子',
    );
  }

  String _getLanguageDisplay() {
    final flag = _getFlag(languageCode);
    return '$flag $languageName频道';
  }

  String _getFlag(String code) {
  final language =
      LanguageConfig.findByCode(code);

  if (language != null) {
    return language.flag;
  }

  final script =
      ScriptConfig.findByCode(code);

  if (script != null) {
    for (final languageCode
        in script.languageCodes) {
      final ownerLanguage =
          LanguageConfig.findByCode(
        languageCode,
      );

      if (ownerLanguage != null) {
        return ownerLanguage.flag;
      }
    }
  }

  return '🌐';
}
}
