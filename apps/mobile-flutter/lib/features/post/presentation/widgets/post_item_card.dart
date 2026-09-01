import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/widgets/user_name_display.dart';
import '../../domain/models/post_model.dart';
import '../cubit/post_cubit.dart';

class PostItemCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;
  final bool showUserInfo;
  final bool showLanguageBadge;
  final String languageCode;

  const PostItemCard({
    super.key,
    required this.post,
    this.onTap,
    this.showUserInfo = true,
    this.showLanguageBadge = true,
    this.languageCode = 'zh',
  });

  static const double imageHeight = 210;
  static const double imageSpacing = 6;

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';

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
    final title = post.title?.trim() ?? '';
    final content = post.content?.trim() ?? '';
    final images = List<String>.from(post.imageUrls ?? const <String>[]);
    final postLanguageCode = post.languageCode?.trim().isNotEmpty == true
        ? post.languageCode!
        : languageCode;

    return InkWell(
      onTap: onTap ??
          () {
            final postCubit = context.read<PostCubit>();
            final latestBookmarked = postCubit.bookmarkState(
              post.id,
              fallback: post.isBookmarked,
            );

            context.push<void>(
              AppRoutes.postDetailLocation(postId: post.id),
              extra: post.copyWith(isBookmarked: latestBookmarked),
            );
          },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleRow(title: title, postLanguageCode: postLanguageCode),
            if (content.isNotEmpty || images.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildContentAndImages(content: content, images: images),
            ],
            const SizedBox(height: 14),
            _buildPostMetadata(),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow({
    required String title,
    required String postLanguageCode,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title.isNotEmpty ? title : '无标题',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF121212),
              height: 1.35,
            ),
          ),
        ),
        if (showLanguageBadge) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.shade200, width: 0.5),
            ),
            child: Text(
              _getLanguageName(postLanguageCode),
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContentAndImages({
    required String content,
    required List<String> images,
  }) {
    if (images.isEmpty) {
      return _buildContentText(content, maxLines: 4);
    }

    if (images.length == 1) {
      return _buildSingleImageLayout(content: content, imageUrl: images.first);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content.isNotEmpty) ...[
          _buildContentText(content, maxLines: 3),
          const SizedBox(height: 10),
        ],
        _buildMultipleImages(images),
      ],
    );
  }

  Widget _buildContentText(String content, {required int maxLines}) {
    if (content.isEmpty) return const SizedBox.shrink();

    return Text(
      content,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF555555),
        height: 1.55,
      ),
    );
  }

  Widget _buildSingleImageLayout({
    required String content,
    required String imageUrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content.isNotEmpty) ...[
          _buildContentText(content, maxLines: 3),
          const SizedBox(height: 10),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final imageWidth = (constraints.maxWidth - imageSpacing * 2) / 3;
            return _buildNetworkImage(
              imageUrl: imageUrl,
              width: imageWidth,
              height: imageHeight,
              borderRadius: 8,
            );
          },
        ),
      ],
    );
  }

  Widget _buildMultipleImages(List<String> images) {
    final visibleImages = images.take(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageCount = visibleImages.length;
        final itemWidth = (constraints.maxWidth - imageSpacing * 2) / 3;

        return Row(
          children: List.generate(imageCount, (index) {
            final isLastVisibleImage = index == imageCount - 1;
            final remainingCount = images.length - 3;

            return Padding(
              padding: EdgeInsets.only(
                right: index < imageCount - 1 ? imageSpacing : 0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: itemWidth,
                  height: imageHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: visibleImages[index],
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 180),
                        placeholder: (_, _) {
                          return const ColoredBox(color: Color(0xFFF2F3F5));
                        },
                        errorWidget: (_, _, _) {
                          return const ColoredBox(
                            color: Color(0xFFF2F3F5),
                            child: Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                color: Colors.grey,
                                size: 28,
                              ),
                            ),
                          );
                        },
                      ),
                      if (isLastVisibleImage && remainingCount > 0)
                        Container(
                          color: Colors.black45,
                          alignment: Alignment.center,
                          child: Text(
                            '+$remainingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildNetworkImage({
    required String imageUrl,
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 180),
        placeholder: (_, _) {
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFF2F3F5),
          );
        },
        errorWidget: (_, _, _) {
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFF2F3F5),
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image_outlined,
              color: Colors.grey,
              size: 26,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostMetadata() {
    return Row(
      children: [
        if (showUserInfo) ...[
          Expanded(child: UserNameDisplay(uid: post.userId ?? '')),
          const SizedBox(width: 8),
        ] else
          const Spacer(),
        Text(
          _formatTimestamp(post.createdAt),
          style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
        ),
      ],
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'zh':
        return '中文频道';
      case 'en':
        return '英文频道';
      case 'ja':
        return '日文频道';
      case 'ko':
        return '韩文频道';
      case 'es':
        return '西班牙语频道';
      case 'fr':
        return '法语频道';
      case 'de':
        return '德语频道';
      case 'pt':
        return '葡萄牙语频道';
      case 'ru':
        return '俄语频道';
      case 'ar':
        return '阿拉伯语频道';
      case 'th':
        return '泰语频道';
      case 'vi':
        return '越南语频道';
      case 'id':
        return '印尼语频道';
      case 'ms':
        return '马来语频道';
      default:
        return '其他语言频道';
    }
  }
}
