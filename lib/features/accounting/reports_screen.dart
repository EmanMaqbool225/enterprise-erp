import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/database/app_database.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int? selectedFilterAccountId; 

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db = ref.watch(databaseProvider);
    final accountDao = ref.watch(accountDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير المالية وكشوفات الحساب'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: StreamBuilder<List<Voucher>>(
          stream: db.select(db.vouchers).watch(),
          builder: (context, voucherSnapshot) {
            if (voucherSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allVouchers = voucherSnapshot.data ?? [];

            
            final filteredVouchers = selectedFilterAccountId == null
                ? allVouchers
                : allVouchers.where((v) => v.partnerId == selectedFilterAccountId).toList();

            
            double totalReceipts = 0; 
            double totalPayments = 0; 

            for (var v in filteredVouchers) {
              if (v.type == 'سند قبض') {
                totalReceipts += v.amount;
              } else {
                totalPayments += v.amount;
              }
            }

            final netBalance = totalReceipts - totalPayments;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Row(
                  children: [
                    _buildSummaryCard(
                      title: 'إجمالي المقبوضات (الداخل)',
                      amount: totalReceipts,
                      icon: Icons.arrow_downward,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _buildSummaryCard(
                      title: 'إجمالي المصروفات (الخارج)',
                      amount: totalPayments,
                      icon: Icons.arrow_upward,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    _buildSummaryCard(
                      title: 'صافي الرصيد / الحركة',
                      amount: netBalance,
                      icon: Icons.account_balance_wallet,
                      color: netBalance >= 0 ? Colors.blue : Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'تصفية كشف الحساب حسب:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StreamBuilder<List<Account>>(
                            stream: accountDao.watchAllAccounts(),
                            builder: (context, accSnapshot) {
                              final accounts = accSnapshot.data ?? [];
                              return DropdownButtonFormField<int?>(
                                value: selectedFilterAccountId,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('جميع الحسابات (تقرير عام شامل)'),
                                  ),
                                  ...accounts.map((acc) {
                                    return DropdownMenuItem<int?>(
                                      value: acc.id,
                                      child: Text('${acc.code} - ${acc.name} (${acc.type})'),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedFilterAccountId = value;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تفاصيل الحركات المالية (${filteredVouchers.length} حركة)',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Expanded(
                            child: filteredVouchers.isEmpty
                                ? const Center(
                                    child: Text(
                                      'لا توجد حركات مالية مسجلة لهذا التحديد',
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: filteredVouchers.length,
                                    itemBuilder: (context, index) {
                                      final v = filteredVouchers[index];
                                      final isReceive = v.type == 'سند قبض';
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: isReceive ? Colors.green.shade100 : Colors.orange.shade100,
                                          child: Icon(
                                            isReceive ? Icons.add : Icons.remove,
                                            color: isReceive ? Colors.green : Colors.orange,
                                          ),
                                        ),
                                        title: Text(
                                          '${v.type} - رقم السند: ${v.voucherNo}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          'التاريخ: ${v.date.split('T')[0]}${v.referenceInvoiceId != null ? " | فاتورة #${v.referenceInvoiceId}" : ""}',
                                        ),
                                        trailing: Text(
                                          '${isReceive ? "+" : "-"} ${v.amount.toStringAsFixed(2)} ريال',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isReceive ? Colors.green : Colors.orange,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text(
                      '${amount.toStringAsFixed(2)} ريال',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}