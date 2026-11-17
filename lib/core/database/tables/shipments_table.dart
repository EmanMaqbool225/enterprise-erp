import 'package:drift/drift.dart';

class Shipments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get truckNumber => text()();
  TextColumn get supplierName => text()();
  DateTimeColumn get arrivalDate => dateTime()();
  IntColumn get totalCrates => integer()();
  TextColumn get status => text()();
}