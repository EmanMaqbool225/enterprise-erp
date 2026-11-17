import 'package:drift/drift.dart';
import 'accounts_table.dart';

class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  IntColumn get accountId => integer().references(Accounts, #id)();
}
