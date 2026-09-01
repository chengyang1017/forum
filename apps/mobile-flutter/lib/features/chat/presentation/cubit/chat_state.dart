import '../../domain/models/chat_thread.dart';

class ChatState {
  const ChatState({
    this.chats,
    this.isLoading = false,
    this.error,
  });

  final List<ChatThread>? chats;
  final bool isLoading;
  final String? error;

  ChatState copyWith({
    List<ChatThread>? chats,
    bool? isLoading,
    String? error,
    bool clearChats = false,
    bool clearError = false,
  }) {
    return ChatState(
      chats: clearChats ? null : chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}
