import 'package:drift/drift.dart';
import 'suppliers_table.dart';

@DataClassName('ShipmentBatch') 
class Batches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get batchNumber => text().unique()();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  TextColumn get arrivalDate => text()();
  TextColumn get driverName => text().nullable()();
  TextColumn get truckPlate => text().nullable()();
  TextColumn get status => text()(); 
}