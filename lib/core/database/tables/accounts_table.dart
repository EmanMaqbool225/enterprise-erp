import 'package:drift/drift.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get type => text()(); 
  IntColumn get parentId => integer().nullable().references(Accounts, #id)();
  BoolColumn get isActive => boolean().withDefault(Constant(true))();
}
