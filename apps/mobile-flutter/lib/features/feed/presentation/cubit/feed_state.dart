class FeedState {
  const FeedState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  FeedState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FeedState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}
