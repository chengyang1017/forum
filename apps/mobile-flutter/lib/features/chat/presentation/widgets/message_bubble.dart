import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MessageBubble extends StatelessWidget {
  final bool isMe;
  final String? content;
  final String? imageUrl;
  final VoidCallback? onImageTap;

  const MessageBubble({
    super.key,
    required this.isMe,
    this.content,
    this.imageUrl,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: isMe
              ? const Radius.circular(16)
              : const Radius.circular(4),
          bottomRight: isMe
              ? const Radius.circular(4)
              : const Radius.circular(16),
        ),
      ),
      child: content != null && content!.isNotEmpty
          ? Text(
              content!,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            )
          : _buildImage(),
    );
  }

  Widget _buildImage() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const SizedBox();
    }
    return GestureDetector(
      onTap: onImageTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          placeholder: (_, _) => const SizedBox(
            height: 150,
            width: 150,
            child: Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (_, _, _) => const Icon(Icons.broken_image, size: 64),
        ),
      ),
    );
  }
}
