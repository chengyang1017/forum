import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? displayName;
  final double radius;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.displayName,
    this.radius = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final String displayText = (displayName ?? 'U')[0].toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.blue.shade50,
        backgroundImage: hasImage
            ? CachedNetworkImageProvider(imageUrl!)
            : null,
        child: !hasImage
            ? Text(
                displayText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.7,
                  color: Colors.blue,
                ),
              )
            : null,
      ),
    );
  }
}
