import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers/database_provider.dart';
import '../../core/database/app_database.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  Customer? selectedCustomer;
  List<Room> cartRooms = [];
  final totalController = TextEditingController();

  @override
  void dispose() {
    totalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final salesDao = ref.watch(salesDaoProvider);
    final inventoryDao = ref.watch(inventoryDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('نقطة البيع - فاتورة مبيعات جديدة'),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('بيانات الفاتورة', style: theme.textTheme.titleLarge),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      
                      FutureBuilder<List<Customer>>(
                        future: salesDao.getAllCustomers(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final customers = snapshot.data ?? [];
                          return Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<Customer>(
                                  value: selectedCustomer,
                                  decoration: const InputDecoration(
                                    labelText: 'اختر العميل',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  items: customers.map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.name),
                                  )).toList(),
                                  onChanged: (val) => setState(() => selectedCustomer = val),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: theme.colorScheme.secondary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.all(16),
                                ),
                                icon: const Icon(Icons.person_add),
                                onPressed: () => _showAddCustomerDialog(context),
                              ),
                            ],
                          );
                        }
                      ),
                      const SizedBox(height: 16),
                      
                      
                      Text('الغرف المضافة للفاتورة:', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: cartRooms.isEmpty 
                            ? const Center(child: Text('السلة فارغة', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: cartRooms.length,
                                itemBuilder: (context, index) {
                                  final room = cartRooms[index];
                                  return ListTile(
                                    leading: const Icon(Icons.meeting_room, color: Colors.green),
                                    title: Text('غرفة ${room.roomNumber}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() => cartRooms.removeAt(index));
                                      },
                                    ),
                                  );
                                },
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: totalController,
                        decoration: const InputDecoration(
                          labelText: 'المبلغ الإجمالي للفاتورة (ريال)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: (selectedCustomer == null || cartRooms.isEmpty || totalController.text.isEmpty) 
                            ? null : () => _saveInvoice(context),
                        icon: const Icon(Icons.save),
                        label: const Text('حفظ وإصدار الفاتورة'),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            
            Expanded(
              flex: 2,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الغرف الجاهزة للبيع (انقر للإضافة للسلة)', style: theme.textTheme.titleLarge),
                      const Divider(),
                      Expanded(
                        child: StreamBuilder<List<Room>>(
                          stream: inventoryDao.watchAllRooms(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            final readyRooms = (snapshot.data ?? []).where((r) => r.status == 'جاهز').toList();

                            if (readyRooms.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.remove_shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    const Text('لا توجد غرف جاهزة للبيع حالياً', style: TextStyle(color: Colors.grey, fontSize: 18)),
                                    const SizedBox(height: 8),
                                    const Text('اذهب إلى قسم المخزون وأضف غرفة بحالة "جاهز"', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              );
                            }

                            return GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.2,
                              ),
                              itemCount: readyRooms.length,
                              itemBuilder: (context, index) {
                                final room = readyRooms[index];
                                final isAdded = cartRooms.any((r) => r.id == room.id);
                                
                                return InkWell(
                                  onTap: isAdded ? null : () {
                                    setState(() => cartRooms.add(room));
                                  },
                                  child: Card(
                                    color: isAdded ? Colors.grey.shade200 : Colors.green.shade50,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(color: isAdded ? Colors.grey : Colors.green.shade300, width: 1.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.meeting_room, size: 40, color: isAdded ? Colors.grey : Colors.green),
                                        const SizedBox(height: 8),
                                        Text('غرفة ${room.roomNumber}', 
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isAdded ? Colors.grey : Colors.green)),
                                        if (isAdded) const Text('مضافة للسلة', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                      ],
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

  
  Future<void> _saveInvoice(BuildContext context) async {
    try {
      final salesDao = ref.read(salesDaoProvider);
      final inventoryDao = ref.read(inventoryDaoProvider);
      final total = double.parse(totalController.text);

      final invoiceId = await salesDao.insertInvoice(
        SalesInvoicesCompanion(
          invoiceNo: drift.Value('INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'),
          customerId: drift.Value(selectedCustomer!.id),
          date: drift.Value(DateTime.now().toIso8601String().split('T')[0]),
          totalAmount: drift.Value(total),
          paymentType: const drift.Value('نقدي'),
        )
      );

      final items = <SalesInvoiceItemsCompanion>[];
      final pricePerRoom = total / cartRooms.length;
      
      for (var room in cartRooms) {
        items.add(
          SalesInvoiceItemsCompanion(
            invoiceId: drift.Value(invoiceId),
            roomId: drift.Value(room.id),
            quantity: const drift.Value(1.0),
            unitPrice: drift.Value(pricePerRoom),
            totalPrice: drift.Value(pricePerRoom)
          )
        );
        await inventoryDao.updateRoomStatus(room.id, 'مباع');
      }
      
      await salesDao.insertInvoiceItems(items);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إصدار الفاتورة بنجاح!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  
  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة عميل جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم العميل', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              try {
                await ref.read(salesDaoProvider).insertCustomer(
                  CustomersCompanion( 
                    name: drift.Value(nameController.text.trim()),
                    phone: drift.Value(phoneController.text.trim()),
                  ),
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                setState(() { selectedCustomer = null; });
              } catch (e) {
                 if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل الحفظ: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}