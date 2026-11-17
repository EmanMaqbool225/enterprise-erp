import 'package:drift/drift.dart';
import 'customers_table.dart';
import 'currencies_table.dart';

class SalesInvoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNo => text().unique()();
  IntColumn get customerId => integer().references(Customers, #id)();
  TextColumn get date => text()();
  TextColumn get paymentType => text()(); 
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount => real()();
  IntColumn get currencyId => integer().references(Currencies, #id)();
}