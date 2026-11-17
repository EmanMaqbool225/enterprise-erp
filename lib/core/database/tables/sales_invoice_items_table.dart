import 'package:drift/drift.dart';
import 'sales_invoices_table.dart';
import 'rooms_table.dart';

class SalesInvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(SalesInvoices, #id)();
  IntColumn get roomId => integer().references(Rooms, #id)();
  
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();
}