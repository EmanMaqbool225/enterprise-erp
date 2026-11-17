import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/database_provider.dart';
import '../../core/database/app_database.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salesDao = ref.watch(salesDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المبيعات والفواتير'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.push('/pos'); 
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('فاتورة مبيعات جديدة'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سجل الفواتير الأخيرة',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<SalesInvoice>>(
                stream: salesDao.watchAllInvoices(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final invoices = snapshot.data ?? [];

                  if (invoices.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 80, color: theme.colorScheme.secondary.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text('لا توجد فواتير مبيعات حتى الآن.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('انقر على "فاتورة مبيعات جديدة" للبدء بالبيع.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = invoices[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.receipt)),
                          title: Text('رقم الفاتورة: ${invoice.invoiceNo}'),
                          subtitle: Text('التاريخ: ${invoice.date} | الدفع: ${invoice.paymentType}'),
                          trailing: Text('${invoice.totalAmount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
    );
  }
}