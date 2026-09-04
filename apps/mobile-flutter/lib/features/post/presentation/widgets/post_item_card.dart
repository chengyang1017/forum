import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';
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

  String _formatTimestamp(BuildContext context, DateTime? dateTime) {
    if (dateTime == null) return '';

    final l10n = AppLocalizations.of(context)!;
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) return l10n.justNow;
    if (difference.inHours < 1) {
      return '${difference.inMinutes}${l10n.minutesAgo}';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}${l10n.hoursAgo}';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}${l10n.daysAgo}';
    }

    return MaterialLocalizations.of(context).formatShortDate(dateTime);
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
      onTap:
          onTap ??
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
            _buildTitleRow(
              context,
              title: title,
              postLanguageCode: postLanguageCode,
            ),
            if (content.isNotEmpty || images.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildContentAndImages(context, content: content, images: images),
            ],
            const SizedBox(height: 14),
            _buildPostMetadata(context),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(
    BuildContext context, {
    required String title,
    required String postLanguageCode,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title.isNotEmpty ? title : l10n.get('untitled'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              height: 1.35,
            ),
          ),
        ),
        if (showLanguageBadge) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.32),
                width: 0.5,
              ),
            ),
            child: Text(
              _getLanguageName(context, postLanguageCode),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContentAndImages(
    BuildContext context, {
    required String content,
    required List<String> images,
  }) {
    if (images.isEmpty) {
      return _buildContentText(context, content, maxLines: 4);
    }

    if (images.length == 1) {
      return _buildSingleImageLayout(
        context,
        content: content,
        imageUrl: images.first,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content.isNotEmpty) ...[
          _buildContentText(context, content, maxLines: 3),
          const SizedBox(height: 10),
        ],
        _buildMultipleImages(context, images),
      ],
    );
  }

  Widget _buildContentText(
    BuildContext context,
    String content, {
    required int maxLines,
  }) {
    if (content.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      content,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 15,
        color: colorScheme.onSurface.withValues(alpha: 0.72),
        height: 1.55,
      ),
    );
  }

  Widget _buildSingleImageLayout(
    BuildContext context, {
    required String content,
    required String imageUrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content.isNotEmpty) ...[
          _buildContentText(context, content, maxLines: 3),
          const SizedBox(height: 10),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final imageWidth = (constraints.maxWidth - imageSpacing * 2) / 3;
            return _buildNetworkImage(
              context,
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

  Widget _buildMultipleImages(BuildContext context, List<String> images) {
    final visibleImages = images.take(3).toList();
    final placeholderColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;

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
                          return ColoredBox(color: placeholderColor);
                        },
                        errorWidget: (_, _, _) {
                          return ColoredBox(
                            color: placeholderColor,
                            child: const Center(
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

  Widget _buildNetworkImage(
    BuildContext context, {
    required String imageUrl,
    required double width,
    required double height,
    required double borderRadius,
  }) {
    final placeholderColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;

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
            color: placeholderColor,
          );
        },
        errorWidget: (_, _, _) {
          return Container(
            width: width,
            height: height,
            color: placeholderColor,
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

  Widget _buildPostMetadata(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        if (showUserInfo) ...[
          Expanded(child: UserNameDisplay(uid: post.userId ?? '')),
          const SizedBox(width: 8),
        ] else
          const Spacer(),
        Text(
          _formatTimestamp(context, post.createdAt),
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  String _getLanguageName(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context)!;
    final normalized = code.trim();
    final lower = normalized.replaceAll('_', '-').toLowerCase();
    final uiLanguageCode = Localizations.localeOf(context).languageCode;

    if (lower == 'chunom' ||
        lower == 'vi-hani' ||
        lower == 'vi-hnom' ||
        lower == 'vi-nom') {
      final vietnamese = LanguageConfig.findByCode('vi');
      final languageName = l10n.translateLanguage('vi');
      final scriptName =
          vietnamese?.scriptNameOf('Hnom', uiLanguageCode) ??
          l10n.get('nomWritingSystem');
      return l10n.getWithArgs('channelBadge', <String, String>{
        'language': '$languageName · $scriptName',
      });
    }

    if (normalized.contains(':')) {
      final parts = normalized.split(':');
      if (parts.length == 2) {
        final language = LanguageConfig.findByCode(parts.first);
        final languageName = language == null
            ? l10n.translateLanguage(parts.first)
            : l10n.translateLanguage(parts.first) == parts.first
            ? language.nameOf(uiLanguageCode)
            : l10n.translateLanguage(parts.first);
        final scriptName =
            language?.scriptNameOf(parts.last, uiLanguageCode) ??
            ScriptConfig.findByCode(parts.last)?.nameOf(uiLanguageCode) ??
            parts.last;
        return l10n.getWithArgs('channelBadge', <String, String>{
          'language': '$languageName · $scriptName',
        });
      }
    }

    final language = LanguageConfig.findByCode(normalized);
    final translated = l10n.translateLanguage(normalized);
    final languageName = translated != normalized
        ? translated
        : language?.nameOf(uiLanguageCode) ?? l10n.get('otherLanguage');

    return l10n.getWithArgs('channelBadge', <String, String>{
      'language': languageName,
    });
  }
}
