import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onEmoji;
  final VoidCallback onImage;
  final bool isLoading;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onEmoji,
    required this.onImage,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined, size: 26),
                color: Colors.grey[600],
                onPressed: onEmoji,
              ),
              IconButton(
                icon: const Icon(Icons.image_outlined, size: 26),
                color: Colors.grey[600],
                onPressed: isLoading ? null : onImage,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: '输入消息...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send_rounded, size: 26),
                      color: Colors.blue,
                      onPressed: onSend,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}