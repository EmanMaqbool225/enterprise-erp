import 'package:drift/drift.dart';
import 'suppliers_table.dart';
import 'batches_table.dart';
import 'currencies_table.dart';

class PurchaseInvoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNo => text().unique()();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  IntColumn get batchId => integer().references(Batches, #id)();
  TextColumn get date => text()();
  TextColumn get paymentType => text()(); 
  RealColumn get totalAmount => real()();
  IntColumn get currencyId => integer().references(Currencies, #id)();
}