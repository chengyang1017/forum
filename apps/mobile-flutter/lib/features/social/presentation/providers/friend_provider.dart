import 'package:flutter/foundation.dart';

import '../../domain/repositories/friend_repository.dart';

class FriendProvider extends ChangeNotifier {
  FriendProvider({required FriendRepository repository})
    : _repository = repository;

  final FriendRepository _repository;

  List<String>? _friendUids;
  bool _isLoading = false;
  String? _error;

  List<String>? get friendUids => _friendUids;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFriends() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _friendUids = await _repository.getFriends();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<String>> watchFriends() {
    return _repository.watchFriends();
  }

  void clear() {
    _friendUids = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
