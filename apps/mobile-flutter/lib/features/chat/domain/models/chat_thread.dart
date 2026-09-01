final class ChatThread {
  const ChatThread({
    required this.id,
    required this.participantIds,
    required this.lastMessage,
    required this.updatedAt,
    required this.unreadCountByUser,
  });

  final String id;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime? updatedAt;
  final Map<String, int> unreadCountByUser;

  String otherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (userId) => userId != currentUserId,
      orElse: () => '',
    );
  }

  int unreadCountFor(String userId) => unreadCountByUser[userId] ?? 0;
}
