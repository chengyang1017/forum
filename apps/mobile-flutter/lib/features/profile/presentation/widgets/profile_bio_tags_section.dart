import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';

class ProfileBioTagsSection extends StatelessWidget {
  final String bio;
  final List<String> tags;
  final AppLocalizations l10n;
  final VoidCallback onEditBio;
  final VoidCallback onEditTags;

  const ProfileBioTagsSection({
    super.key,
    required this.bio,
    required this.tags,
    required this.l10n,
    required this.onEditBio,
    required this.onEditTags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bio.isNotEmpty) ...[
            GestureDetector(
              onTap: onEditBio,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 20,
                    color: Colors.blue.shade300,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bio,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit, size: 14, color: Colors.grey.shade400),
                ],
              ),
            ),
          ],
          if (bio.isNotEmpty && tags.isNotEmpty) const SizedBox(height: 16),
          if (tags.isNotEmpty)
            GestureDetector(
              onTap: onEditTags,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...tags.map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '# $tag',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  //添加标签按钮
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          if (bio.isEmpty && tags.isEmpty) ...[
            GestureDetector(
              onTap: onEditBio,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.introYourself,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.format_quote_rounded,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onEditTags,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.addTagsHint,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
