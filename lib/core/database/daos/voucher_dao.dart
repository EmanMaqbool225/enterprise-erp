import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/vouchers_table.dart'; 

part 'voucher_dao.g.dart';

@DriftAccessor(tables: [Vouchers])
class VoucherDao extends DatabaseAccessor<AppDatabase> with _$VoucherDaoMixin {
  VoucherDao(AppDatabase db) : super(db);

  
  Stream<List<Voucher>> watchAllVouchers() {
    return select(vouchers).watch();
  }

  
  Future<int> insertVoucher(VouchersCompanion voucher) {
    return into(vouchers).insert(voucher);
  }

  
  Future<void> deleteVoucher(int id) async {
    await (delete(vouchers)..where((t) => t.id.equals(id))).go();
  }
}