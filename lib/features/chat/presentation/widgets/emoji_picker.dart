import 'package:flutter/material.dart';

class EmojiPicker extends StatelessWidget {
  final Function(String) onEmojiSelected;

  const EmojiPicker({
    super.key,
    required this.onEmojiSelected,
  });

  static const List<String> _emojis = [
    '😀', '😂', '🤣', '😍', '🥰', '😘', '😜', '😎',
    '🤩', '🥳', '😢', '😡', '👍', '👎', '🙏', '💪',
    '🔥', '❤️', '💔', '🎉', '🌟', '💯', '✅', '❌',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _emojis.map((emoji) => GestureDetector(
              onTap: () {
                onEmojiSelected(emoji);
                Navigator.pop(context);
              },
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            )).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}