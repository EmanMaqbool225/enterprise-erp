import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;


import 'tables/users_table.dart';
import 'tables/fiscal_years_table.dart';
import 'tables/currencies_table.dart';
import 'tables/accounts_table.dart';
import 'tables/customers_table.dart';
import 'tables/suppliers_table.dart';
import 'tables/rooms_table.dart';
import 'tables/batches_table.dart';
import 'tables/sales_invoices_table.dart';
import 'tables/sales_invoice_items_table.dart';
import 'tables/purchase_invoices_table.dart';
import 'tables/vouchers_table.dart';
import 'daos/inventory_dao.dart';
import 'daos/sales_dao.dart';
import 'tables/shipments_table.dart';
import 'daos/shipment_dao.dart';
import 'daos/account_dao.dart';
import 'daos/voucher_dao.dart';



import 'daos/auth_dao.dart';

part 'app_database.g.dart';


@DriftDatabase(
  tables: [
    Users,
    FiscalYears,
    Currencies,
    Accounts,
    Customers,
    Suppliers,
    Rooms,
    Batches,
    SalesInvoices,
    SalesInvoiceItems,
    PurchaseInvoices,
    Vouchers,
    Shipments,
    Accounts,
  ],
  daos: [
    AuthDao,
    InventoryDao, 
    SalesDao,
    ShipmentDao,
    AccountDao,
    VoucherDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        
        
        
        
        await into(users).insert(UsersCompanion.insert(
          name: 'المدير العام',
          username: 'admin',
          passwordHash: 'admin123', 
          role: 'admin',
        ));

        
        await into(currencies).insert(CurrenciesCompanion.insert(
          code: 'YER',
          name: 'ريال يمني',
          exchangeRate: 1.0,
          isBase: const Value(true),
        ));
        await into(currencies).insert(CurrenciesCompanion.insert(
          code: 'SAR',
          name: 'ريال سعودي',
          exchangeRate: 140.0,
        ));
        await into(currencies).insert(CurrenciesCompanion.insert(
          code: 'USD',
          name: 'دولار أمريكي',
          exchangeRate: 530.0,
        ));
      },
      onUpgrade: (Migrator m, int from, int to) async {
        
      },
      beforeOpen: (details) async {
        
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'EnterpriseERP', 'erp_system_v4.sqlite'));
    
    return NativeDatabase.createInBackground(file);
  });
}