class FriendState {
  const FriendState({
    this.friendUids,
    this.isLoading = false,
    this.error,
  });

  final List<String>? friendUids;
  final bool isLoading;
  final String? error;

  FriendState copyWith({
    List<String>? friendUids,
    bool clearFriendUids = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FriendState(
      friendUids: clearFriendUids ? null : friendUids ?? this.friendUids,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}
