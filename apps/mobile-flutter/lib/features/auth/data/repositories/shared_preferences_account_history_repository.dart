import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/saved_account.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/account_history_repository.dart';

final class SharedPreferencesAccountHistoryRepository
    implements AccountHistoryRepository {
  static const _storageKey = 'saved_accounts';
  static const _maxAccounts = 5;

  @override
  Future<List<SavedAccount>> loadAccounts() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);

    if (encoded == null || encoded.isEmpty) {
      return const <SavedAccount>[];
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) {
        return const <SavedAccount>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (value) => SavedAccount.fromMap(Map<String, dynamic>.from(value)),
          )
          .where((account) => account.userId.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <SavedAccount>[];
    }
  }

  @override
  Future<List<SavedAccount>> saveAccount(UserModel user) async {
    final accounts = List<SavedAccount>.from(await loadAccounts());
    final account = SavedAccount.fromUser(user);

    accounts.removeWhere((item) => item.userId == account.userId);
    accounts.insert(0, account);

    if (accounts.length > _maxAccounts) {
      accounts.removeRange(_maxAccounts, accounts.length);
    }

    await _write(accounts);
    return List<SavedAccount>.unmodifiable(accounts);
  }

  @override
  Future<List<SavedAccount>> removeAccount(String userId) async {
    final accounts = List<SavedAccount>.from(await loadAccounts())
      ..removeWhere((account) => account.userId == userId);

    await _write(accounts);
    return List<SavedAccount>.unmodifiable(accounts);
  }

  Future<void> _write(List<SavedAccount> accounts) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(accounts.map((account) => account.toMap()).toList()),
    );
  }
}
