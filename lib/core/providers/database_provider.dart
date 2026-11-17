import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/daos/inventory_dao.dart';
import '../database/daos/auth_dao.dart';
import '../database/daos/sales_dao.dart';
import '../database/daos/shipment_dao.dart';
import '../database/daos/account_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});


final inventoryDaoProvider = Provider<InventoryDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.inventoryDao; 
});


final authDaoProvider = Provider<AuthDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.authDao;
});


final salesDaoProvider = Provider<SalesDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.salesDao;
});
final shipmentDaoProvider = Provider<ShipmentDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.shipmentDao;
});

final accountDaoProvider = Provider<AccountDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.accountDao;
});