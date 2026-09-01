import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/friend_repository.dart';
import 'friend_state.dart';

class FriendCubit extends Cubit<FriendState> {
  FriendCubit({required FriendRepository repository})
    : _repository = repository,
      super(const FriendState());

  final FriendRepository _repository;

  List<String>? get friendUids => state.friendUids;
  bool get isLoading => state.isLoading;
  String? get error => state.error;

  Future<void> loadFriends() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final friendUids = await _repository.getFriends();
      emit(state.copyWith(friendUids: friendUids));
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Stream<List<String>> watchFriends() {
    return _repository.watchFriends();
  }

  void clear() {
    emit(const FriendState());
  }
}
