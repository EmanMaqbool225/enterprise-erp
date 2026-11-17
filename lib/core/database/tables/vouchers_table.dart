import 'package:drift/drift.dart';
import 'currencies_table.dart';

class Vouchers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get voucherNo => text().unique()();
  TextColumn get type => text()(); 
  TextColumn get date => text()();
  IntColumn get partnerId => integer().nullable()(); 
  RealColumn get amount => real()();
  IntColumn get currencyId => integer().references(Currencies, #id)();
  IntColumn get referenceInvoiceId => integer().nullable()(); 
}