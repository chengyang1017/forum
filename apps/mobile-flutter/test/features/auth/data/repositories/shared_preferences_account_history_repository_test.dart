import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glyphora_mobile/features/auth/data/repositories/shared_preferences_account_history_repository.dart';
import 'package:glyphora_mobile/features/auth/domain/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesAccountHistoryRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = SharedPreferencesAccountHistoryRepository();
  });

  UserModel user(String id) {
    return UserModel(
      id: id,
      username: 'user-$id',
      email: '$id@example.com',
      nickname: 'User $id',
      avatar: 'https://example.com/$id.png',
    );
  }

  test('saves newest account first and de-duplicates by user id', () async {
    await repository.saveAccount(user('1'));
    await repository.saveAccount(user('2'));
    final accounts = await repository.saveAccount(user('1'));

    expect(accounts.map((account) => account.userId), <String>['1', '2']);
    expect(accounts.first.username, 'User 1');
  });

  test('keeps at most five saved accounts', () async {
    for (var index = 1; index <= 6; index++) {
      await repository.saveAccount(user('$index'));
    }

    final accounts = await repository.loadAccounts();

    expect(accounts, hasLength(5));
    expect(accounts.map((account) => account.userId), <String>[
      '6',
      '5',
      '4',
      '3',
      '2',
    ]);
  });

  test('reads the legacy saved_accounts JSON shape', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'saved_accounts':
          '[{"uid":"legacy","email":"legacy@example.com","username":"Legacy","avatar":"https://example.com/legacy.png"}]',
    });

    final accounts = await repository.loadAccounts();

    expect(accounts, hasLength(1));
    expect(accounts.single.userId, 'legacy');
    expect(accounts.single.username, 'Legacy');
  });

  test('removes an account by user id', () async {
    await repository.saveAccount(user('1'));
    await repository.saveAccount(user('2'));

    final accounts = await repository.removeAccount('2');

    expect(accounts.map((account) => account.userId), <String>['1']);
  });
}
