import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers/database_provider.dart';
import '../../core/database/app_database.dart';

class VouchersScreen extends ConsumerStatefulWidget {
  const VouchersScreen({super.key});

  @override
  ConsumerState<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends ConsumerState<VouchersScreen> {
  final voucherNoController = TextEditingController();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  String voucherType = 'سند قبض';
  int? selectedPartnerId;
  int? selectedInvoiceId; 

  final List<String> voucherTypes = ['سند قبض', 'سند صرف'];

  @override
  void dispose() {
    voucherNoController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountDao = ref.watch(accountDaoProvider);
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة سندات القبض والصرف اليومية'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Expanded(
              flex: 1,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تحرير سند مالـي', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const Divider(),
                        const SizedBox(height: 16),

                        TextField(
                          controller: voucherNoController,
                          decoration: const InputDecoration(
                            labelText: 'رقم السند',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.confirmation_number),
                          ),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: voucherType,
                          decoration: const InputDecoration(
                            labelText: 'نوع السند',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.receipt_long),
                          ),
                          items: voucherTypes.map((type) {
                            return DropdownMenuItem(value: type, child: Text(type));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              voucherType = value!;
                              selectedInvoiceId = null; 
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        
                        StreamBuilder<List<Account>>(
                          stream: accountDao.watchAllAccounts(),
                          builder: (context, snapshot) {
                            final accounts = snapshot.data ?? [];
                            return DropdownButtonFormField<int>(
                              value: selectedPartnerId,
                              decoration: const InputDecoration(
                                labelText: 'الحساب المرتبط (صندوق/عميل/مورد)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.account_balance),
                              ),
                              items: accounts.map((acc) {
                                return DropdownMenuItem<int>(
                                  value: acc.id,
                                  child: Text('${acc.code} - ${acc.name}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedPartnerId = value;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        
                        if (voucherType == 'سند قبض')
                          StreamBuilder<List<SalesInvoice>>(
                            stream: db.select(db.salesInvoices).watch(),
                            builder: (context, snapshot) {
                              final invoices = snapshot.data ?? [];
                              return DropdownButtonFormField<int?>(
                                value: selectedInvoiceId,
                                decoration: const InputDecoration(
                                  labelText: 'ربط بفاتورة مبيعات (اختياري)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.description),
                                ),
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('بدون ربط بفاتورة'),
                                  ),
                                  ...invoices.map((inv) {
                                    return DropdownMenuItem<int?>(
                                      value: inv.id,
                                      child: Text('فاتورة رقم #${inv.id} - الإجمالي: ${inv.totalAmount}'),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedInvoiceId = value;
                                  });
                                },
                              );
                            },
                          )
                        else
                          StreamBuilder<List<PurchaseInvoice>>(
                            stream: db.select(db.purchaseInvoices).watch(),
                            builder: (context, snapshot) {
                              final invoices = snapshot.data ?? [];
                              return DropdownButtonFormField<int?>(
                                value: selectedInvoiceId,
                                decoration: const InputDecoration(
                                  labelText: 'ربط بفاتورة مشتريات (اختياري)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.description),
                                ),
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('بدون ربط بفاتورة'),
                                  ),
                                  ...invoices.map((inv) {
                                    return DropdownMenuItem<int?>(
                                      value: inv.id,
                                      child: Text('فاتورة شراء #${inv.id} - الإجمالي: ${inv.totalAmount}'),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedInvoiceId = value;
                                  });
                                },
                              );
                            },
                          ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: amountController,
                          decoration: const InputDecoration(
                            labelText: 'المبلغ',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.money),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'البيان (التفاصيل والسبب)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _saveVoucher(context),
                          icon: const Icon(Icons.save),
                          label: const Text('حفظ وترحيل السند'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),

            
            Expanded(
              flex: 2,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('سجل السندات اليومية', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(),
                      const SizedBox(height: 8),
                      
                      Expanded(
                        child: StreamBuilder<List<Voucher>>(
                          stream: db.select(db.vouchers).watch(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final vouchers = snapshot.data ?? [];

                            if (vouchers.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    const Text('سجّل أول سند قبض أو صرف لتبدأ العمليات المالية النشطة', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: vouchers.length,
                              itemBuilder: (context, index) {
                                final v = vouchers[index];
                                final isReceive = v.type == 'سند قبض';
                                final invoiceInfo = v.referenceInvoiceId != null
                                    ? ' | مرتبط بفاتورة #${v.referenceInvoiceId}'
                                    : '';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(color: isReceive ? Colors.green.shade200 : Colors.orange.shade200, width: 1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isReceive ? Colors.green.shade100 : Colors.orange.shade100,
                                      child: Icon(
                                        isReceive ? Icons.arrow_downward : Icons.arrow_upward,
                                        color: isReceive ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                    title: Text('سند رقم: ${v.voucherNo} - المبلغ: ${v.amount} ريال', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('النوع: ${v.type}$invoiceInfo | التاريخ: ${v.date.split('T')[0]}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        await (db.delete(db.vouchers)..where((t) => t.id.equals(v.id))).go();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('تم حذف السند بنجاح'), backgroundColor: Colors.red),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
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
        ),
      ),
    );
  }

  Future<void> _saveVoucher(BuildContext context) async {
    if (voucherNoController.text.trim().isEmpty || amountController.text.trim().isEmpty || selectedPartnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رقم السند، المبلغ، واختيار الحساب'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final db = ref.read(databaseProvider);
      final amount = double.parse(amountController.text.trim());

      await db.into(db.vouchers).insert(
            VouchersCompanion.insert(
              voucherNo: voucherNoController.text.trim(),
              type: voucherType,
              partnerId: drift.Value(selectedPartnerId),
              amount: amount,
              currencyId: 1,
              date: DateTime.now().toIso8601String(),
              referenceInvoiceId: drift.Value(selectedInvoiceId), 
            ),
          );

      voucherNoController.clear();
      amountController.clear();
      descriptionController.clear();
      setState(() {
        selectedPartnerId = null;
        selectedInvoiceId = null;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ وترحيل السند بنجاح!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}