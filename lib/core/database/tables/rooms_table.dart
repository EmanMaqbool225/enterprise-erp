import 'package:drift/drift.dart';

class Rooms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get roomNumber => integer()();
  IntColumn get floorNumber => integer()();
  TextColumn get status => text()(); 
}