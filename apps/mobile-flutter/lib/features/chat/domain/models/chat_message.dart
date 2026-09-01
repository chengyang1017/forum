final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.type,
    required this.senderId,
    required this.content,
    required this.imageUrl,
    required this.word,
    required this.timestamp,
    required this.editedAt,
    required this.hiddenFor,
    required this.status,
  });

  final String id;
  final String type;
  final String senderId;
  final String content;
  final String? imageUrl;
  final String? word;
  final DateTime? timestamp;
  final DateTime? editedAt;
  final Set<String> hiddenFor;
  final String status;

  bool get isDeleted => status == 'deleted';
  bool get isEdited => !isDeleted && editedAt != null;
  bool isHiddenFor(String userId) => hiddenFor.contains(userId);

  String get displayContent {
    if (isDeleted) {
      return '此消息已删除';
    }

    if (content.trim().isNotEmpty) {
      return content;
    }

    if (type == 'vocab' && (word?.trim().isNotEmpty ?? false)) {
      return word!.trim();
    }

    return '';
  }
}
