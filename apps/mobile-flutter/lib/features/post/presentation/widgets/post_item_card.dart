import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../domain/models/post_model.dart';
import '../providers/post_provider.dart' as postProv;
import '../../../../core/widgets/user_name_display.dart';

class PostItemCard extends StatelessWidget {
  final PostModel post;

  /// 自定义点击行为。
  /// 不传时保持原本行为：打开帖子详情页。
  final VoidCallback? onTap;

  /// FeedScreen 传 true：
  /// 显示帖子发布者的用户名。
  ///
  /// ProfileScreen 可以传 false：
  /// 避免在用户自己的主页重复显示用户名。
  final bool showUserInfo;

  /// 是否显示帖子所属的语言频道。
  final bool showLanguageBadge;

  /// 当帖子本身没有 languageCode 时使用的备用语言代码。
  final String languageCode;

  const PostItemCard({
    super.key,
    required this.post,
    this.onTap,
    this.showUserInfo = true,
    this.showLanguageBadge = true,
    this.languageCode = 'zh',
  });

  // ============================================================
  // 图片尺寸
  // ============================================================
  /// 每张图片的统一高度。
  static const double imageHeight = 210;

  /// 图片之间的间隔。
  static const double imageSpacing = 6;

  // /// 单张图片显示在正文右侧时的宽度。
  // static const double singleImageWidth = 120;

  // /// 单张图片显示在正文右侧时的高度。
  // ///
  // /// 想调整单图高度，主要修改这里。
  // static const double singleImageHeight = 82;

  // /// 多张图片横向排列时，每张图片的高度。
  // ///
  // /// 想调整多图高度，主要修改这里。
  // static const double multipleImageHeight = 210;

  /// 多张图片之间的间距。
  //static const double imageSpacing = 6;

  // ============================================================
  // 时间格式化
  // ============================================================

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    }

    if (difference.inHours < 1) {
      return '${difference.inMinutes} 分钟前';
    }

    if (difference.inDays < 1) {
      return '${difference.inHours} 小时前';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    }

    return '${dateTime.month}月${dateTime.day}日';
  }

  // ============================================================
  // 页面主体
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final title = post.title?.trim() ?? '';
    final content = post.content?.trim() ?? '';

    final images = List<String>.from(post.imageUrls ?? const <String>[]);

    final postLanguageCode = post.languageCode?.trim().isNotEmpty == true
        ? post.languageCode!
        : languageCode;

    return InkWell(
      onTap:
          onTap ??
          () {
            final postProvider = context.read<postProv.PostProvider>();

            final latestBookmarked = postProvider.bookmarkState(
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
            // 标题和语言频道标签。
            _buildTitleRow(title: title, postLanguageCode: postLanguageCode),

            // 正文和图片。
            if (content.isNotEmpty || images.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildContentAndImages(content: content, images: images),
            ],

            const SizedBox(height: 14),

            // 作者和发布时间。
            _buildPostMetadata(),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 标题区域
  // ============================================================

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

  // ============================================================
  // 正文和图片布局
  // ============================================================

  Widget _buildContentAndImages({
    required String content,
    required List<String> images,
  }) {
    // 没有图片时，只显示正文。
    if (images.isEmpty) {
      return _buildContentText(content, maxLines: 4);
    }

    // 只有一张图片时：
    // 正文显示在左边，图片显示在右边。
    if (images.length == 1) {
      return _buildSingleImageLayout(content: content, imageUrl: images.first);
    }

    // 两张及以上图片时：
    // 正文显示在上方，图片横向排列在下方。
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

  // ============================================================
  // 正文文字
  // ============================================================

  Widget _buildContentText(String content, {required int maxLines}) {
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

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

  // ============================================================
  // 单张图片布局
  // ============================================================

  Widget _buildSingleImageLayout({
    required String content,
    required String imageUrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 正文。
        if (content.isNotEmpty) ...[
          _buildContentText(content, maxLines: 3),
          const SizedBox(height: 10),
        ],

        // 根据页面宽度计算三列图片中每一张的宽度。
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

  // ============================================================
  // 多张图片布局
  // ============================================================

  Widget _buildMultipleImages(List<String> images) {
    // 最多显示前三张。
    final visibleImages = images.take(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageCount = visibleImages.length;

        // 根据当前可用宽度自动计算每张图片宽度。
        // final itemWidth =
        //     (
        //       constraints.maxWidth -
        //       imageSpacing * (imageCount - 1)
        //     ) /
        //     imageCount;
        // 永远按照三列计算宽度。
        // 所以无论有 1、2、3 张，每张图的尺寸都一样。
        final itemWidth = (constraints.maxWidth - imageSpacing * 2) / 3;

        return Row(
          children: List.generate(imageCount, (index) {
            final isLastVisibleImage = index == imageCount - 1;

            // 如果总共有 5 张图片：
            // 当前只显示 3 张，则 remainingCount 为 2。
            final remainingCount = images.length - 3;

            return Padding(
              padding: EdgeInsets.only(
                right: index < imageCount - 1 ? imageSpacing : 0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: itemWidth,

                  // 多张图片的统一高度。
                  // 想让多图区域更高，就修改 multipleImageHeight。
                  height: imageHeight,

                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: visibleImages[index],
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 180),
                        placeholder: (_, __) {
                          return const ColoredBox(color: Color(0xFFF2F3F5));
                        },
                        errorWidget: (_, __, ___) {
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

                      // 图片超过三张时，
                      // 在第三张图片上显示剩余数量。
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

  // ============================================================
  // 通用网络图片
  // ============================================================

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
        placeholder: (_, __) {
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFF2F3F5),
          );
        },
        errorWidget: (_, __, ___) {
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

  // ============================================================
  // 作者和时间
  // ============================================================

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

  // ============================================================
  // 语言名称
  // ============================================================

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
