// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipment_dao.dart';

// ignore_for_file: type=lint
mixin _$ShipmentDaoMixin on DatabaseAccessor<AppDatabase> {
  $ShipmentsTable get shipments => attachedDatabase.shipments;
  ShipmentDaoManager get managers => ShipmentDaoManager(this);
}

class ShipmentDaoManager {
  final _$ShipmentDaoMixin _db;
  ShipmentDaoManager(this._db);
  $$ShipmentsTableTableManager get shipments =>
      $$ShipmentsTableTableManager(_db.attachedDatabase, _db.shipments);
}
