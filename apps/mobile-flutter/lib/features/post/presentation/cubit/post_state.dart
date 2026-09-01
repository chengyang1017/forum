class PostState {
  const PostState({
    this.isLoading = false,
    this.error,
    this.bookmarkStates = const <String, bool>{},
  });

  final bool isLoading;
  final String? error;
  final Map<String, bool> bookmarkStates;

  PostState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, bool>? bookmarkStates,
  }) {
    return PostState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      bookmarkStates: bookmarkStates ?? this.bookmarkStates,
    );
  }
}
