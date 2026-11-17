import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/users_table.dart';

part 'auth_dao.g.dart';

@DriftAccessor(tables: [Users])
class AuthDao extends DatabaseAccessor<AppDatabase> with _$AuthDaoMixin {
  AuthDao(AppDatabase db) : super(db);

  
  Future<User?> login(String username, String passwordHash) {
    return (select(users)
          ..where((t) => 
              t.username.equals(username) & 
              t.passwordHash.equals(passwordHash) & 
              t.isActive.equals(true)))
        .getSingleOrNull();
  }
}