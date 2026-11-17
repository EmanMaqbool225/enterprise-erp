import 'package:drift/drift.dart';
import 'accounts_table.dart';

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get whatsappNumber => text().nullable()();
  TextColumn get address => text().nullable()();
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();
}
