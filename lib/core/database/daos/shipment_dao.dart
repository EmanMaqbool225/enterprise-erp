import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/shipments_table.dart';

part 'shipment_dao.g.dart';

@DriftAccessor(tables: [Shipments])
class ShipmentDao extends DatabaseAccessor<AppDatabase> with _$ShipmentDaoMixin {
  ShipmentDao(AppDatabase db) : super(db);

  
  Stream<List<Shipment>> watchActiveShipments() {
    return (select(shipments)..where((t) => t.status.equals('نشطة'))).watch();
  }

  
  Stream<List<Shipment>> watchAllShipments() {
    return select(shipments).watch();
  }

  
  Future<int> insertShipment(ShipmentsCompanion shipment) {
    return into(shipments).insert(shipment);
  }

  
  Future<bool> updateShipmentStatus(int id, String newStatus) async {
    return await (update(shipments)..where((t) => t.id.equals(id)))
        .write(ShipmentsCompanion(status: Value(newStatus))) > 0;
  }
}