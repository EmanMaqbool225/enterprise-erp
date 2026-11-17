import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/accounts_table.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(AppDatabase db) : super(db);

  
  Stream<List<Account>> watchAllAccounts() {
    return select(accounts).watch();
  }

  
  Future<List<Account>> getAllAccounts() {
    return select(accounts).get();
  }

  
  Future<int> insertAccount(AccountsCompanion account) {
    return into(accounts).insert(account);
  }

  
  Future<bool> updateAccount(Account account) {
    return update(accounts).replace(account);
  }

  
  Future<void> deleteAccount(int id) async {
    await (delete(accounts)..where((t) => t.id.equals(id))).go();
  }
}