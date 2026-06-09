// lib/widgets/post_image_preview.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostImagePreview extends StatelessWidget {
  final List<String> images;
  final double size;

  const PostImagePreview({
    super.key,
    required this.images,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox();

    // 最多显示3张
    final displayImages = images.take(3).toList();
    final remaining = images.length - 3;

    return SizedBox(
      height: size,
      child: Row(
        children: [
          ...displayImages.map((url) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: size,
                  height: size,
                  color: Colors.grey[200],
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: size,
                  height: size,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          )),
          // 第4张显示"+N"
          if (remaining > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: size,
                height: size,
                color: Colors.black54,
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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