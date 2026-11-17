import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers/database_provider.dart';
import '../../core/database/app_database.dart';

class ShipmentsScreen extends ConsumerStatefulWidget {
  const ShipmentsScreen({super.key});

  @override
  ConsumerState<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends ConsumerState<ShipmentsScreen> {
  final truckController = TextEditingController();
  final supplierController = TextEditingController();
  final cratesController = TextEditingController();

  @override
  void dispose() {
    truckController.dispose();
    supplierController.dispose();
    cratesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shipmentDao = ref.watch(shipmentDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الشحنات وحمولات الشاحنات'),
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
                      Text('استلام شحنة جديدة', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: truckController,
                        decoration: const InputDecoration(
                          labelText: 'رقم / لوحة الشاحنة',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.local_shipping),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: supplierController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المورد',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: cratesController,
                        decoration: const InputDecoration(
                          labelText: 'عدد الصناديق (وزن 30 كجم)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory_2),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _saveShipment(context),
                        icon: const Icon(Icons.add_box),
                        label: const Text('تسجيل وحفظ الشحنة'),
                      ),
                    ],
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
                      Text('الشحنات النشطة في المستودع', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(),
                      const SizedBox(height: 8),
                      
                      Expanded(
                        child: StreamBuilder<List<Shipment>>(
                          stream: shipmentDao.watchActiveShipments(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final shipments = snapshot.data ?? [];

                            if (shipments.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    const Text('لا توجد شحنات نشطة حالياً', style: TextStyle(color: Colors.grey, fontSize: 18)),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: shipments.length,
                              itemBuilder: (context, index) {
                                final shipment = shipments[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(color: Colors.green.shade200, width: 1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.green.shade100,
                                      child: const Icon(Icons.local_shipping, color: Colors.green),
                                    ),
                                    title: Text('شاحنة رقم: ${shipment.truckNumber} - المورد: ${shipment.supplierName}',
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('عدد الصناديق: ${shipment.totalCrates} صندوق (30 كجم) | التاريخ: ${shipment.arrivalDate.toIso8601String().split('T')[0]}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.check_circle, color: Colors.green),
                                      tooltip: 'إنهاء وتفريغ الشحنة',
                                      onPressed: () async {
                                        await shipmentDao.updateShipmentStatus(shipment.id, 'مكتملة');
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('تم تحديث حالة الشحنة إلى مكتملة'), backgroundColor: Colors.green),
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

  
  Future<void> _saveShipment(BuildContext context) async {
    if (truckController.text.trim().isEmpty || 
        supplierController.text.trim().isEmpty || 
        cratesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إكمال جميع الحقول المطلوبة'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final shipmentDao = ref.read(shipmentDaoProvider);
      final cratesCount = int.parse(cratesController.text.trim());

      await shipmentDao.insertShipment(
        ShipmentsCompanion.insert(
          truckNumber: truckController.text.trim(),
          supplierName: supplierController.text.trim(),
          arrivalDate: DateTime.now(),
          totalCrates: cratesCount,
          status: 'نشطة', 
        ),
      );

      truckController.clear();
      supplierController.clear();
      cratesController.clear();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم استلام وتسجيل الشحنة بنجاح!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحفظ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}