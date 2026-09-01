import '../models/saved_account.dart';
import '../models/user_model.dart';

abstract interface class AccountHistoryRepository {
  Future<List<SavedAccount>> loadAccounts();

  Future<List<SavedAccount>> saveAccount(UserModel user);

  Future<List<SavedAccount>> removeAccount(String userId);
}
