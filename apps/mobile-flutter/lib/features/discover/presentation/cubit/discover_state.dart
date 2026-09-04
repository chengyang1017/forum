class DiscoverState {
  const DiscoverState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  DiscoverState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DiscoverState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}
