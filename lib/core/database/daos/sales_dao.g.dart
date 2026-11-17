// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_dao.dart';

// ignore_for_file: type=lint
mixin _$SalesDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountsTable get accounts => attachedDatabase.accounts;
  $CustomersTable get customers => attachedDatabase.customers;
  $CurrenciesTable get currencies => attachedDatabase.currencies;
  $SalesInvoicesTable get salesInvoices => attachedDatabase.salesInvoices;
  $RoomsTable get rooms => attachedDatabase.rooms;
  $SalesInvoiceItemsTable get salesInvoiceItems =>
      attachedDatabase.salesInvoiceItems;
  SalesDaoManager get managers => SalesDaoManager(this);
}

class SalesDaoManager {
  final _$SalesDaoMixin _db;
  SalesDaoManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$CurrenciesTableTableManager get currencies =>
      $$CurrenciesTableTableManager(_db.attachedDatabase, _db.currencies);
  $$SalesInvoicesTableTableManager get salesInvoices =>
      $$SalesInvoicesTableTableManager(_db.attachedDatabase, _db.salesInvoices);
  $$RoomsTableTableManager get rooms =>
      $$RoomsTableTableManager(_db.attachedDatabase, _db.rooms);
  $$SalesInvoiceItemsTableTableManager get salesInvoiceItems =>
      $$SalesInvoiceItemsTableTableManager(
          _db.attachedDatabase, _db.salesInvoiceItems);
}
