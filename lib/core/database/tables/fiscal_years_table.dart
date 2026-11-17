import 'package:drift/drift.dart';

class FiscalYears extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get yearName => text()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();
  BoolColumn get isClosed => boolean().withDefault(Constant(false))();
}
