import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../social/domain/repositories/friend_repository.dart';
import '../../domain/models/discover_user.dart';
import '../../domain/repositories/discover_repository.dart';
import 'discover_state.dart';

class DiscoverCubit extends Cubit<DiscoverState> {
  DiscoverCubit({
    required DiscoverRepository repository,
    required ChatRepository chatRepository,
    required FriendRepository friendRepository,
  }) : _repository = repository,
       _chatRepository = chatRepository,
       _friendRepository = friendRepository,
       super(const DiscoverState());

  final DiscoverRepository _repository;
  final ChatRepository _chatRepository;
  final FriendRepository _friendRepository;

  Stream<List<DiscoverUser>> watchAllUsers(String currentUserId) {
    return _repository.watchAllUsers(currentUserId);
  }

  Future<String> getOrCreateChat(String otherUserId) {
    return _chatRepository.getOrCreateChat(otherUserId);
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await _friendRepository.sendRequest(targetUserId);
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
      rethrow;
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  void clear() {
    emit(const DiscoverState());
  }
}
