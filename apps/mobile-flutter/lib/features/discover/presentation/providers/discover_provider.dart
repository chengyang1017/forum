import 'package:flutter/foundation.dart';

import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../social/domain/repositories/friend_repository.dart';
import '../../domain/models/discover_user.dart';
import '../../domain/repositories/discover_repository.dart';

class DiscoverProvider extends ChangeNotifier {
  DiscoverProvider({
    required DiscoverRepository repository,
    required ChatRepository chatRepository,
    required FriendRepository friendRepository,
  }) : _repository = repository,
       _chatRepository = chatRepository,
       _friendRepository = friendRepository;

  final DiscoverRepository _repository;
  final ChatRepository _chatRepository;
  final FriendRepository _friendRepository;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<DiscoverUser>> watchAllUsers(String currentUserId) {
    return _repository.watchAllUsers(currentUserId);
  }

  Future<String> getOrCreateChat(String otherUserId) {
    return _chatRepository.getOrCreateChat(otherUserId);
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _friendRepository.sendRequest(targetUserId);
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
