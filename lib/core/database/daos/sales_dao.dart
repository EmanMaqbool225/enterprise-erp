import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sales_invoices_table.dart';
import '../tables/sales_invoice_items_table.dart';
import '../tables/customers_table.dart';
import '../tables/currencies_table.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [SalesInvoices, SalesInvoiceItems, Customers, Currencies])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(AppDatabase db) : super(db);

  Stream<List<SalesInvoice>> watchAllInvoices() {
    return select(salesInvoices).watch();
  }

  Future<List<Customer>> getAllCustomers() {
    return select(customers).get();
  }

  
  Future<int> insertCustomer(CustomersCompanion customer) {
    return into(customers).insert(customer);
  }

  Future<int> insertInvoice(SalesInvoicesCompanion invoice) {
    return into(salesInvoices).insert(invoice);
  }
  
  Future<void> insertInvoiceItems(List<SalesInvoiceItemsCompanion> items) async {
    await batch((b) {
      b.insertAll(salesInvoiceItems, items);
    });
  }
}