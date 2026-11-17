import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/rooms_table.dart';
import '../tables/batches_table.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(tables: [Rooms, Batches])
class InventoryDao extends DatabaseAccessor<AppDatabase> with _$InventoryDaoMixin {
  InventoryDao(AppDatabase db) : super(db);

  
  Stream<List<Room>> watchAllRooms() {
    return select(rooms).watch();
  }

  
  Future<int> insertRoom(RoomsCompanion room) {
    return into(rooms).insert(room);
  }

  Future<bool> updateRoomStatus(int roomId, String newStatus) async {
    return await (update(rooms)..where((t) => t.id.equals(roomId)))
        .write(RoomsCompanion(status: Value(newStatus))) > 0;
  }

  Future<List<ShipmentBatch>> getActiveBatches() {
    return (select(batches)
          ..where((t) => t.status.isNotValue('مباع')))
        .get();
  }
}